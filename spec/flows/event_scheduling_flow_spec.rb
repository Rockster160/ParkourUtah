require 'rails_helper'

RSpec.describe "Event Scheduling Flow", type: :model do
  describe "creating and managing a class schedule" do
    it "creates schedule, generates events, manages cancellations" do
      instructor = create(:user, :instructor, full_name: "Coach Jane")

      # Create recurring schedule
      schedule = create(:event_schedule,
        instructor: instructor,
        title: "Beginner Parkour",
        city: "Salt Lake City",
        day_of_week: :tuesday,
        hour_of_day: 17,
        minute_of_day: 30,
        cost_in_pennies: 1000,
        start_date: 1.month.ago,
        tags: "classes, beginner"
      )

      expect(schedule).to be_persisted
      expect(schedule.time_of_day).to eq("5:30 PM")
      expect(schedule.cost_in_dollars).to eq(10.0)
      expect(schedule.host_name).to eq("Coach Jane")

      # Generate events for a week range
      monday = Time.zone.now.beginning_of_week
      events = schedule.new_events_for_time_range(monday, monday + 2.weeks)
      # Should have Tuesday events
      events.each do |event|
        expect(event.date.wday).to eq(2) # Tuesday
      end

      # Create and cancel a specific event
      event = schedule.events.create!(date: Time.zone.now)
      expect(event).to be_persisted
      expect(event.cancelled?).to be false

      event.cancel!
      expect(event.reload.cancelled?).to be true

      event.uncancel!
      expect(event.reload.cancelled?).to be false
    end
  end

  describe "event subscription" do
    it "subscribes users to class reminders" do
      user = create(:user)
      instructor = create(:user, :instructor)
      schedule = create(:event_schedule, instructor: instructor)

      sub = user.event_subscriptions.create!(event_schedule: schedule)
      expect(sub).to be_persisted
      expect(user.is_subscribed_to?(schedule.id)).to be true
      expect(schedule.subscribed_users).to include(user)
    end
  end

  describe "event with spot" do
    it "creates schedule using a spot instead of address" do
      instructor = create(:user, :instructor)
      spot = create(:spot, title: "Liberty Park")
      schedule = create(:event_schedule, instructor: instructor, spot: spot, full_address: nil)
      expect(schedule).to be_valid
      expect(schedule.spot).to eq(spot)
    end
  end

  describe "schedule date strings" do
    it "parses and formats start/end dates" do
      schedule = create(:event_schedule)
      schedule.start_str_date = "Jan 15, 2025"
      expect(schedule.start_date.month).to eq(1)
      expect(schedule.start_date.day).to eq(15)
      expect(schedule.start_str_date).to eq("Jan 15, 2025")
    end
  end
end
