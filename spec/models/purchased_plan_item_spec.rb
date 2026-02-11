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
  end
end
