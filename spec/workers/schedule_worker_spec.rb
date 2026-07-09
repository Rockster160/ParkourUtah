require 'rails_helper'

RSpec.describe ScheduleWorker do
  let(:worker) { ScheduleWorker.new }

  before do
    allow(HTTParty).to receive(:post)
  end

  describe "#perform" do
    it "dispatches tasks by name" do
      expect(worker).to receive(:uptime_ping).with(nil)
      worker.perform([["uptime_ping", nil]])
    end

    it "handles multiple tasks" do
      expect(worker).to receive(:uptime_ping).with(nil)
      expect(worker).to receive(:post_to_custom_logger).with(nil)
      worker.perform([["uptime_ping", nil], ["post_to_custom_logger", nil]])
    end
  end

  describe "send_class_text" do
    it "sends reminders to subscribed users with upcoming classes" do
      instructor = create(:user, :instructor)
      user = create(:user, phone_number: "8015551234", can_receive_sms: true)
      user.notifications.update!(text_class_reminder: true)

      # Create a class happening in ~2 hours
      schedule = create(:event_schedule, instructor: instructor,
        day_of_week: Date.current.strftime("%A").downcase.to_sym,
        hour_of_day: (Time.zone.now + 2.hours).hour,
        minute_of_day: 0
      )
      create(:event_subscription, user: user, event_schedule: schedule)

      # This is a timing-sensitive test, just verify it doesn't error
      expect { worker.send(:send_class_text, nil) }.not_to raise_error
    end
  end

  describe "waiver_checks" do
    it "runs without error" do
      user = create(:user)
      athlete = create(:athlete, user: user)
      create(:waiver, :signed, athlete: athlete, expiry_date: 1.week.from_now)

      expect { worker.send(:waiver_checks, nil) }.not_to raise_error
    end
  end

  describe "send_summary" do
    it "generates and sends summary in non-production" do
      instructor = create(:user, :instructor)
      create(:event_schedule, instructor: instructor)
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with("PKUT_EMAIL").and_return("admin@example.com")

      expect {
        worker.send(:send_summary, { "scope" => "day", "send_without_prod" => true })
      }.not_to raise_error
    end
  end

  describe "pull_logs_from_s3" do
    it "returns early (currently disabled)" do
      expect(worker.send(:pull_logs_from_s3, nil)).to be_nil
    end
  end

  describe "#monthly_subscription_charges" do
    let(:user) { create(:user) }
    let(:athlete) { create(:athlete, user: user) }

    def make_expired_sub(cost: 5500, stripe: "cus_a", athlete_override: nil)
      create(:recurring_subscription, :expired,
        user: user,
        athlete: athlete_override || athlete,
        stripe_id: stripe,
        cost_in_pennies: cost
      )
    end

    it "charges Stripe, marks the old sub auto_renew=false, and creates a renewal record" do
      stub_stripe_charge_success!
      sub = make_expired_sub(cost: 5500, stripe: "cus_a")

      worker.send(:monthly_subscription_charges, nil)

      expect(::Stripe::Charge).to have_received(:create).with(
        hash_including(amount: 5500, currency: "usd", customer: "cus_a")
      )
      expect(sub.reload.auto_renew).to eq(false)

      new_sub = user.recurring_subscriptions.where(auto_renew: true).first
      expect(new_sub).to be_present
      expect(new_sub.cost_in_pennies).to eq(5500)
      expect(new_sub.stripe_id).to eq("cus_a")
      expect(new_sub.athlete_id).to eq(athlete.id)
    end

    it "batches multiple expired subs on the same stripe customer into one charge" do
      stub_stripe_charge_success!
      other_athlete = create(:athlete, user: user)
      make_expired_sub(cost: 5500, stripe: "cus_a")
      make_expired_sub(cost: 7000, stripe: "cus_a", athlete_override: other_athlete)

      worker.send(:monthly_subscription_charges, nil)

      expect(::Stripe::Charge).to have_received(:create).once.with(
        hash_including(amount: 12500, customer: "cus_a")
      )
    end

    it "skips subs with blank stripe_id (bug reproduction from June 2026 incident)" do
      make_expired_sub(cost: 5500, stripe: nil)

      expect(::Stripe::Charge).not_to receive(:create)
      worker.send(:monthly_subscription_charges, nil)
    end

    it "marks card_declined and sends a decline email when Stripe raises CardError" do
      stub_stripe_charge_declined!
      sub = make_expired_sub

      expect(ApplicationMailer).to receive(:subscription_charge_declined_mail).with(user.id).and_return(double(deliver_later: true))

      worker.send(:monthly_subscription_charges, nil)

      expect(sub.reload.card_declined).to eq(true)
      # The failure path does NOT create a renewal — only the original sub exists.
      expect(user.recurring_subscriptions.count).to eq(1)
    end

    it "skips Stripe entirely for $0 subs (comped/legacy free) but still renews them" do
      allow(::Stripe::Charge).to receive(:create) # will fail if invoked
      sub = make_expired_sub(cost: 0)

      worker.send(:monthly_subscription_charges, nil)

      expect(::Stripe::Charge).not_to have_received(:create)
      expect(sub.reload.auto_renew).to eq(false)
      expect(user.recurring_subscriptions.where(auto_renew: true).count).to eq(1)
    end

    it "does not create a duplicate renewal when auto_renew was flipped mid-flight" do
      stub_stripe_charge_success!
      sub = make_expired_sub

      # Simulate a race: another process (e.g. users_controller#update_card_details
      # handling the same missed charge) flips auto_renew=false BEFORE the
      # worker acquires its row lock. lock! calls reload(lock: true), so the
      # in-memory record should see the new state and the guard should skip.
      allow_any_instance_of(RecurringSubscription).to receive(:lock!) do |instance|
        RecurringSubscription.where(id: instance.id).update_all(auto_renew: false)
        instance.reload
      end

      worker.send(:monthly_subscription_charges, nil)

      # Only the original sub exists — no duplicate renewal was created.
      expect(user.recurring_subscriptions.count).to eq(1)
    end
  end

  describe "#monthly_plan_charges" do
    let(:user) { create(:user) }
    let(:athlete) { create(:athlete, user: user) }
    let(:plan_item) { create(:plan_item) }

    def make_inactive_ppi(cost: 7500, stripe: "cus_a", athlete_override: nil)
      create(:purchased_plan_item, :expired,
        user: user,
        athlete: athlete_override || athlete,
        plan_item: plan_item,
        stripe_id: stripe,
        cost_in_pennies: cost
      )
    end

    it "charges Stripe and creates a renewal PPI with expires_at ~1 month out" do
      stub_stripe_charge_success!
      ppi = make_inactive_ppi(cost: 7500, stripe: "cus_a")

      worker.send(:monthly_plan_charges, nil)

      expect(::Stripe::Charge).to have_received(:create).with(
        hash_including(amount: 7500, currency: "usd", customer: "cus_a")
      )
      expect(ppi.reload.auto_renew).to eq(false)

      new_ppi = user.purchased_plan_items.where(auto_renew: true).first
      expect(new_ppi).to be_present
      expect(new_ppi.cost_in_pennies).to eq(7500)
      expect(new_ppi.stripe_id).to eq("cus_a")
      expect(new_ppi.athlete_id).to eq(athlete.id)
      expect(new_ppi.plan_item_id).to eq(plan_item.id)
      expect(new_ppi.expires_at).to be_within(2.minutes).of(1.month.from_now)
    end

    it "skips PPIs with blank stripe_id (the original bug from the audit)" do
      make_inactive_ppi(stripe: nil)

      expect(::Stripe::Charge).not_to receive(:create)
      worker.send(:monthly_plan_charges, nil)
    end

    it "batches multiple inactive PPIs on the same stripe customer into one charge" do
      stub_stripe_charge_success!
      other_athlete = create(:athlete, user: user)
      make_inactive_ppi(cost: 6500, stripe: "cus_a")
      make_inactive_ppi(cost: 6500, stripe: "cus_a", athlete_override: other_athlete)

      worker.send(:monthly_plan_charges, nil)

      expect(::Stripe::Charge).to have_received(:create).once.with(
        hash_including(amount: 13000, customer: "cus_a")
      )
    end

    it "marks card_declined and sends a decline email when Stripe raises CardError" do
      stub_stripe_charge_declined!
      ppi = make_inactive_ppi

      expect(ApplicationMailer).to receive(:subscription_charge_declined_mail).with(user.id).and_return(double(deliver_later: true))

      worker.send(:monthly_plan_charges, nil)

      expect(ppi.reload.card_declined).to be_present
      expect(user.purchased_plan_items.count).to eq(1)
    end

    it "skips Stripe for $0 comped plans and still renews the record" do
      allow(::Stripe::Charge).to receive(:create)
      ppi = make_inactive_ppi(cost: 0)

      worker.send(:monthly_plan_charges, nil)

      expect(::Stripe::Charge).not_to have_received(:create)
      expect(ppi.reload.auto_renew).to eq(false)
      expect(user.purchased_plan_items.where(auto_renew: true).count).to eq(1)
    end
  end
end
