require 'rails_helper'

RSpec.describe "Subscription Flow", type: :model do
  describe "purchasing and using a subscription" do
    it "creates subscription, assigns to athlete, uses for class" do
      user = create(:user, credits: 0)
      athlete = create(:athlete, user: user)
      instructor = create(:user, :instructor)
      schedule = create(:event_schedule, instructor: instructor, cost_in_pennies: 1000,
        accepts_unlimited_classes: true, tags: "classes")
      event = create(:event, event_schedule: schedule)

      # Step 1: Purchase subscription (simulating what store does)
      sub = user.recurring_subscriptions.create!(cost_in_pennies: 5500, stripe_id: "cus_test")
      expect(sub).to be_persisted
      expect(user.recurring_subscriptions.unassigned.count).to eq(1)

      # Step 2: Assign to athlete
      sub.assign_to_athlete(athlete)
      expect(sub.reload.athlete_id).to eq(athlete.id)
      expect(sub.expires_at).to be > Time.zone.now
      expect(athlete.has_unlimited_access?).to be true

      # Step 3: Attend class using subscription
      result = athlete.attend_class(event, instructor)
      expect(result).to be true
      expect(athlete.attendances.first.type_of_charge).to eq("Unlimited Subscription")
      expect(sub.reload.usages).to eq(1)
    end

    it "stacks subscription time when re-assigned" do
      user = create(:user)
      athlete = create(:athlete, user: user)

      sub1 = create(:recurring_subscription, user: user, athlete: athlete, expires_at: 2.weeks.from_now)
      sub2 = create(:recurring_subscription, user: user)
      sub2.assign_to_athlete(athlete)

      # Should extend from existing expiration, not from now
      expect(sub2.reload.expires_at).to be > 2.weeks.from_now
    end

    it "handles subscription expiration" do
      user = create(:user, credits: 0)
      athlete = create(:athlete, user: user)
      create(:recurring_subscription, :expired, user: user, athlete: athlete)

      instructor = create(:user, :instructor)
      schedule = create(:event_schedule, instructor: instructor, cost_in_pennies: 1000)
      event = create(:event, event_schedule: schedule)

      expect(athlete.has_unlimited_access?).to be false
      result = athlete.attend_class(event, instructor)
      expect(result).to be false # no credits, expired sub
    end
  end

  describe "plan-based subscription flow" do
    it "creates plan item, purchases it, assigns to athlete, uses free classes" do
      user = create(:user, credits: 0)
      athlete = create(:athlete, user: user)
      plan_item = create(:plan_item,
        free_items: [{ "tags" => "classes", "count" => 2, "interval" => "week" }],
        discount_items: [{ "tags" => "classes", "discount" => "50%" }]
      )

      # Simulate purchase
      purchased = user.purchased_plan_items.create!(
        plan_item: plan_item,
        cost_in_pennies: 7500,
        free_items: plan_item.free_items,
        discount_items: plan_item.discount_items
      )
      purchased.assign_to_athlete(athlete)
      expect(purchased.reload.athlete_id).to eq(athlete.id)
      expect(purchased.expires_at).to be > Time.zone.now

      # Set up class
      instructor = create(:user, :instructor)
      schedule = create(:event_schedule, instructor: instructor, cost_in_pennies: 1000,
        tags: "classes", accepts_unlimited_classes: false, accepts_trial_classes: false)
      event = create(:event, event_schedule: schedule)

      # Attend class using plan
      result = athlete.attend_class(event, instructor)
      expect(result).to be true
      expect(athlete.attendances.first.type_of_charge).to eq("Plan")
    end
  end
end
