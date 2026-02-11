require 'rails_helper'

RSpec.describe "Class Attendance Flow", type: :model do
  let(:instructor) { create(:user, :instructor) }
  let(:schedule) do
    create(:event_schedule,
      instructor: instructor,
      cost_in_pennies: 1000,
      tags: "classes",
      accepts_trial_classes: true,
      accepts_unlimited_classes: true
    )
  end
  let(:event) { create(:event, event_schedule: schedule, date: Time.zone.now) }

  describe "paying with credits" do
    it "deducts credits and creates attendance" do
      user = create(:user, credits: 100)
      athlete = create(:athlete, user: user)
      create(:waiver, :signed, athlete: athlete)

      result = athlete.attend_class(event, instructor)

      expect(result).to be true
      expect(user.reload.credits).to eq(90) # 10 credits deducted (1000 pennies = $10)
      expect(athlete.attendances.count).to eq(1)
      expect(athlete.attendances.first.type_of_charge).to eq("Credits")
    end

    it "fails when user has insufficient credits" do
      user = create(:user, credits: 5)
      athlete = create(:athlete, user: user)

      result = athlete.attend_class(event, instructor)

      expect(result).to be false
      expect(athlete.attendances.count).to eq(0)
    end
  end

  describe "paying with trial class" do
    it "uses trial and creates attendance" do
      user = create(:user, credits: 0)
      athlete = create(:athlete, user: user)
      trial = create(:trial_class, athlete: athlete)

      result = athlete.attend_class(event, instructor)

      expect(result).to be true
      expect(trial.reload.used).to be true
      expect(athlete.attendances.first.type_of_charge).to eq("Trial Class")
    end

    it "prefers unlimited subscription over trial" do
      user = create(:user, credits: 0)
      athlete = create(:athlete, user: user)
      create(:trial_class, athlete: athlete)
      create(:recurring_subscription, :active, user: user, athlete: athlete)

      result = athlete.attend_class(event, instructor)

      expect(result).to be true
      expect(athlete.attendances.first.type_of_charge).to eq("Unlimited Subscription")
    end
  end

  describe "paying with unlimited subscription" do
    it "increments usage and creates attendance" do
      user = create(:user, credits: 0)
      athlete = create(:athlete, user: user)
      sub = create(:recurring_subscription, :active, user: user, athlete: athlete)

      result = athlete.attend_class(event, instructor)

      expect(result).to be true
      expect(sub.reload.usages).to eq(1)
      expect(athlete.attendances.first.type_of_charge).to eq("Unlimited Subscription")
    end

    it "skips when event doesn't accept unlimited" do
      schedule.update!(accepts_unlimited_classes: false)
      user = create(:user, credits: 100)
      athlete = create(:athlete, user: user)
      create(:recurring_subscription, :active, user: user, athlete: athlete)

      result = athlete.attend_class(event, instructor)

      expect(result).to be true
      # Falls through to credits
      expect(athlete.attendances.first.type_of_charge).to eq("Credits")
    end
  end

  describe "paying with plan" do
    it "uses plan free items and creates attendance" do
      user = create(:user, credits: 0)
      athlete = create(:athlete, user: user)
      plan_item = create(:plan_item, free_items: [{ "tags" => "classes", "count" => 2, "interval" => "week" }])
      create(:purchased_plan_item, :active, user: user, athlete: athlete, plan_item: plan_item,
        free_items: [{ "tags" => ["classes"], "count" => 2, "interval" => "week" }])

      result = athlete.attend_class(event, instructor)

      expect(result).to be true
      expect(athlete.attendances.first.type_of_charge).to eq("Plan")
    end
  end

  describe "one attendance per athlete per event" do
    it "prevents duplicate attendance" do
      user = create(:user, credits: 200)
      athlete = create(:athlete, user: user)

      athlete.attend_class(event, instructor)
      result = athlete.attend_class(event, instructor)

      expect(result).to be false
      expect(athlete.attendances.count).to eq(1)
    end
  end

  describe "priority order" do
    it "uses unlimited > trial > plan > credits" do
      user = create(:user, credits: 100)
      athlete = create(:athlete, user: user)
      create(:trial_class, athlete: athlete)
      create(:recurring_subscription, :active, user: user, athlete: athlete)

      athlete.attend_class(event, instructor)
      expect(athlete.attendances.first.type_of_charge).to eq("Unlimited Subscription")
    end
  end
end
