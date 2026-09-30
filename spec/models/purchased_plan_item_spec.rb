require 'rails_helper'

RSpec.describe PurchasedPlanItem, type: :model do
  describe "associations" do
    it { should belong_to(:user) }
    it { should belong_to(:plan_item) }
    it { should belong_to(:athlete).optional }
    it { should belong_to(:cart).optional }
  end

  describe "#cost" do
    it "converts pennies to dollars" do
      plan = build(:purchased_plan_item, cost_in_pennies: 7500)
      expect(plan.cost).to eq(75.0)
    end
  end

  describe "#assign_to_athlete" do
    it "assigns athlete and sets expiration" do
      user = create(:user)
      athlete = create(:athlete, user: user)
      plan_item = create(:plan_item)
      plan = create(:purchased_plan_item, user: user, plan_item: plan_item)

      plan.assign_to_athlete(athlete)
      expect(plan.reload.athlete_id).to eq(athlete.id)
      expect(plan.expires_at).to be > Time.zone.now
    end

    it "does nothing with nil athlete" do
      user = create(:user)
      plan_item = create(:plan_item)
      plan = create(:purchased_plan_item, user: user, plan_item: plan_item)
      plan.assign_to_athlete(nil)
      expect(plan.reload.athlete_id).to be_nil
    end

    it "expires a monthly plan one month out" do
      user = create(:user)
      athlete = create(:athlete, user: user)
      plan = create(:purchased_plan_item, user: user,
        plan_item: create(:plan_item, billing_interval: "month"))

      plan.assign_to_athlete(athlete)
      expect(plan.reload.expires_at).to be_within(2.minutes).of(1.month.from_now)
    end

    it "expires a yearly plan a full year out, not a month" do
      user = create(:user)
      athlete = create(:athlete, user: user)
      plan = create(:purchased_plan_item, user: user,
        plan_item: create(:plan_item, billing_interval: "year"))

      plan.assign_to_athlete(athlete)
      expect(plan.reload.expires_at).to be_within(2.minutes).of(1.year.from_now)
    end
  end

  describe "scopes" do
    let(:user) { create(:user) }
    let(:athlete) { create(:athlete, user: user) }
    let(:plan_item) { create(:plan_item) }

    it ".active returns non-expired plans" do
      active = create(:purchased_plan_item, :active, user: user, athlete: athlete, plan_item: plan_item)
      expired = create(:purchased_plan_item, user: user, athlete: athlete, plan_item: plan_item, expires_at: 1.day.ago)
      expect(PurchasedPlanItem.active).to include(active)
      expect(PurchasedPlanItem.active).not_to include(expired)
    end

    it ".assigned returns plans with athletes" do
      assigned = create(:purchased_plan_item, :active, user: user, athlete: athlete, plan_item: plan_item)
      unassigned = create(:purchased_plan_item, user: user, plan_item: plan_item)
      expect(PurchasedPlanItem.assigned).to include(assigned)
      expect(PurchasedPlanItem.assigned).not_to include(unassigned)
    end

    it ".auto_renew returns auto-renewing plans" do
      auto = create(:purchased_plan_item, user: user, plan_item: plan_item, auto_renew: true)
      manual = create(:purchased_plan_item, user: user, plan_item: plan_item, auto_renew: false)
      expect(PurchasedPlanItem.auto_renew).to include(auto)
      expect(PurchasedPlanItem.auto_renew).not_to include(manual)
    end

    it ".renewable covers assigned plans and unassigned family passes" do
      assigned = create(:purchased_plan_item, :active, user: user, athlete: athlete, plan_item: plan_item)
      unassigned = create(:purchased_plan_item, user: user, plan_item: plan_item)
      family = create(:purchased_plan_item, user: user, athlete: nil, plan_item: create(:plan_item, :family))

      expect(PurchasedPlanItem.renewable).to include(assigned, family)
      expect(PurchasedPlanItem.renewable).not_to include(unassigned)
    end
  end

  describe "family passes" do
    let(:user) { create(:user) }
    let(:plan_item) { create(:plan_item) }
    let(:family_plan_item) { create(:plan_item, :family) }
    let(:yearly_family_plan_item) { create(:plan_item, :family, billing_interval: "year") }

    it "starts covering the account as soon as it is bought, with no athlete" do
      plan = create(:purchased_plan_item, user: user, athlete: nil, plan_item: family_plan_item)

      expect(plan.athlete_id).to be_nil
      expect(plan.expires_at).to be_within(1.minute).of(plan.created_at + 1.month)
      expect(PurchasedPlanItem.active).to include(plan)
    end

    it "bills a yearly family pass a year out, not a month" do
      plan = create(:purchased_plan_item, user: user, athlete: nil, plan_item: yearly_family_plan_item)
      expect(plan.expires_at).to be_within(1.minute).of(plan.created_at + 1.year)
    end

    it "leaves an expiry the renewal flow already set alone" do
      expires_at = 3.days.from_now
      plan = create(:purchased_plan_item, user: user, athlete: nil, plan_item: family_plan_item, expires_at: expires_at)
      expect(plan.expires_at).to be_within(1.second).of(expires_at)
    end

    it "does not start a normal plan before it is assigned" do
      plan = create(:purchased_plan_item, user: user, athlete: nil, plan_item: plan_item)
      expect(plan.expires_at).to be_nil
    end

    it "is not awaiting assignment, so it raises no assign-me prompt" do
      family = create(:purchased_plan_item, user: user, athlete: nil, plan_item: family_plan_item)
      normal = create(:purchased_plan_item, user: user, athlete: nil, plan_item: plan_item)

      expect(family.awaiting_assignment?).to be false
      expect(normal.awaiting_assignment?).to be true
    end
  end
end
