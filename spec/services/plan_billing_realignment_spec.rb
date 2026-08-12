require 'rails_helper'

RSpec.describe PlanBillingRealignment do
  let(:user) { create(:user) }
  let(:athlete) { create(:athlete, user: user) }
  let(:plan_item) { create(:plan_item, name: "Unlimited Monthly Classes") }

  # Mirrors user 6699: paid through 2026-08-02, but assignment on 2026-08-11
  # pushed expires_at out to 2026-09-11.
  let(:paid_through) { Time.zone.parse("2026-08-02 16:10:14") }
  let(:next_expires_at) { Time.zone.parse("2026-09-02 06:00:00") }

  let!(:plan) do
    create(:purchased_plan_item,
      user: user, athlete: athlete, plan_item: plan_item, cart_id: 69666,
      cost_in_pennies: 13000, auto_renew: true, stripe_id: "cus_test",
      expires_at: Time.zone.parse("2026-09-11 12:00:00")
    )
  end

  subject(:service) do
    described_class.new(plan: plan, paid_through: paid_through, next_expires_at: next_expires_at)
  end

  describe "rehearsal" do
    it "touches neither Stripe nor the database" do
      expect(::Stripe::Charge).not_to receive(:create)

      result = service.call

      expect(result.dry_run).to be true
      expect(result.charged_in_pennies).to eq(13000)
      expect { plan.reload }.not_to change { [plan.expires_at, plan.auto_renew] }
      expect(user.purchased_plan_items.count).to eq(1)
    end
  end

  describe "confirmed run" do
    before { stub_stripe_charge_success! }

    it "charges the missed cycle against the plan's own Stripe customer" do
      service.call(confirm: true)

      expect(::Stripe::Charge).to have_received(:create).once.with(
        amount: 13000, currency: "usd", customer: "cus_test"
      )
    end

    it "closes the drifted record at the date it was actually paid through" do
      result = service.call(confirm: true)

      expect(result).to be_success
      expect(plan.reload.expires_at).to be_within(1.second).of(paid_through)
      expect(plan.auto_renew).to be false
    end

    it "opens the successor on the corrected schedule, still assigned to the athlete" do
      new_plan = service.call(confirm: true).new_plan

      expect(new_plan.athlete_id).to eq(athlete.id)
      expect(new_plan.user_id).to eq(user.id)
      expect(new_plan.plan_item_id).to eq(plan_item.id)
      expect(new_plan.cost_in_pennies).to eq(13000)
      expect(new_plan.stripe_id).to eq("cus_test")
      expect(new_plan.auto_renew).to be true
      expect(new_plan.cart_id).to be_nil
      expect(new_plan.expires_at).to be_within(1.second).of(next_expires_at)
    end

    it "leaves exactly one plan covering any given moment" do
      service.call(confirm: true)

      # The drifted record must not stay live alongside its own successor —
      # overlapping active plans double up the per-week free_items allowance.
      travel_to(Time.zone.parse("2026-08-20 12:00:00")) do
        expect(athlete.purchased_plan_items.active.count).to eq(1)
      end
    end

    it "preserves the original record rather than replacing it" do
      expect { service.call(confirm: true) }.to change { user.purchased_plan_items.count }.from(1).to(2)
      expect(PurchasedPlanItem.find_by(id: plan.id)).to be_present
    end

    it "hands the successor to the renewal worker on the target date" do
      new_plan = service.call(confirm: true).new_plan

      travel_to(Time.zone.parse("2026-09-02 07:00:00")) do
        expect(PurchasedPlanItem.assigned.auto_renew.inactive.available).to include(new_plan)
      end
    end

    it "does not hand it over early" do
      new_plan = service.call(confirm: true).new_plan

      travel_to(Time.zone.parse("2026-09-01 07:00:00")) do
        expect(PurchasedPlanItem.assigned.auto_renew.inactive.available).not_to include(new_plan)
      end
    end
  end

  describe "when the card is declined" do
    before { stub_stripe_charge_declined! }

    it "writes nothing at all — no rewritten cycle without a payment behind it" do
      result = service.call(confirm: true)

      expect(result).not_to be_success
      expect(result.error).to include("declined")
      expect(plan.reload.expires_at).to eq(Time.zone.parse("2026-09-11 12:00:00"))
      expect(plan.auto_renew).to be true
      expect(user.purchased_plan_items.count).to eq(1)
    end
  end

  describe "re-running" do
    before { stub_stripe_charge_success! }

    it "refuses to charge a second time once the successor exists" do
      service.call(confirm: true)

      second = described_class.new(plan: plan.reload, paid_through: paid_through, next_expires_at: next_expires_at)
      result = second.call(confirm: true)

      expect(result).not_to be_success
      expect(result.error).to include("already realigned")
      expect(::Stripe::Charge).to have_received(:create).once
      expect(user.purchased_plan_items.count).to eq(2)
    end
  end

  describe "prechecks" do
    it "refuses an unassigned plan" do
      plan.update!(athlete_id: nil)
      expect(service.call(confirm: true).error).to include("not assigned")
    end

    it "refuses a plan with no card on file" do
      plan.update!(stripe_id: nil)
      expect(service.call(confirm: true).error).to include("no Stripe customer")
    end

    it "refuses a $0 plan" do
      plan.update!(cost_in_pennies: 0)
      expect(service.call(confirm: true).error).to include("amount must be positive")
    end

    it "refuses reversed cycle boundaries" do
      backwards = described_class.new(plan: plan, paid_through: next_expires_at, next_expires_at: paid_through)
      expect(backwards.call(confirm: true).error).to include("must fall before")
    end

    it "never reaches Stripe when a precheck fails" do
      expect(::Stripe::Charge).not_to receive(:create)
      plan.update!(stripe_id: "")
      service.call(confirm: true)
    end
  end
end
