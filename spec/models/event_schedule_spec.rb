require 'rails_helper'

RSpec.describe EventSchedule, type: :model do
  describe "associations" do
    it { should belong_to(:instructor) }
    it { should have_many(:events).dependent(:destroy) }
    it { should have_many(:event_subscriptions).dependent(:destroy) }
  end

  describe "validations" do
    it "requires core fields" do
      schedule = EventSchedule.new
      schedule.valid?
      %i[start_date hour_of_day minute_of_day day_of_week cost_in_pennies title city].each do |attr|
        expect(schedule.errors[attr]).to be_present
      end
    end

    it "requires either address or spot" do
      schedule = build(:event_schedule, full_address: nil, spot: nil)
      expect(schedule).not_to be_valid
      expect(schedule.errors[:base]).to include("Event must have either an Address or a Spot attached.")
    end

    it "accepts a full_address" do
      schedule = build(:event_schedule, full_address: "123 Main St", spot: nil)
      expect(schedule).to be_valid
    end

    it "accepts a spot instead of address" do
      spot = create(:spot)
      schedule = build(:event_schedule, full_address: nil, spot: spot)
      expect(schedule).to be_valid
    end

    it "requires at least one payment rule" do
      schedule = build(:event_schedule, payment_per_student: nil, min_payment_per_session: nil, max_payment_per_session: nil)
      expect(schedule).not_to be_valid
      expect(schedule.errors[:base]).to include("Must have at least 1 payment rule set.")
    end
  end

  describe "#cost / #cost_in_dollars" do
    it "converts pennies to dollars" do
      schedule = build(:event_schedule, cost_in_pennies: 1500)
      expect(schedule.cost_in_dollars).to eq(15.0)
    end

    it "sets cost from dollars" do
      schedule = build(:event_schedule)
      schedule.cost = 25.50
      expect(schedule.cost_in_pennies).to eq(2550)
    end
  end

  describe "#time_of_day" do
    it "formats time correctly for PM" do
      schedule = build(:event_schedule, hour_of_day: 17, minute_of_day: 30)
      expect(schedule.time_of_day).to eq("5:30 PM")
    end

    it "formats time correctly for AM" do
      schedule = build(:event_schedule, hour_of_day: 9, minute_of_day: 0)
      expect(schedule.time_of_day).to eq("9:00 AM")
    end
  end

  describe "#time_of_day=" do
    it "parses time string with AM/PM" do
      schedule = build(:event_schedule)
      schedule.time_of_day = "3:30 PM"
      expect(schedule.hour_of_day).to eq(15)
      expect(schedule.minute_of_day).to eq(30)
    end
  end

  describe "#tags=" do
    it "splits comma-separated tags into array" do
      schedule = build(:event_schedule)
      schedule.tags = "classes, intermediate, outdoor"
      expect(schedule.tags).to eq(["classes", "intermediate", "outdoor"])
    end
  end

  describe "#new_events_for_time_range" do
    it "generates events within the date range" do
      schedule = create(:event_schedule, day_of_week: :monday, start_date: 1.month.ago)
      first_date = Time.zone.now.beginning_of_week
      last_date = first_date + 3.weeks
      events = schedule.new_events_for_time_range(first_date, last_date)
      expect(events).to all(be_a(Event))
      events.each do |event|
        expect(event.date.wday).to eq(1) # Monday
      end
    end
  end

  describe "color prepending" do
    it "adds # to 6-character color codes" do
      schedule = build(:event_schedule, color: "FF5733")
      schedule.save!
      expect(schedule.color).to eq("#FF5733")
    end

    it "leaves already-prefixed colors alone" do
      schedule = build(:event_schedule, color: "#FF5733")
      schedule.save!
      expect(schedule.color).to eq("#FF5733")
    end
  end

  describe ".events_for_date" do
    it "returns events for a specific date" do
      schedule = create(:event_schedule, start_date: 1.week.ago, day_of_week: Date.current.strftime("%A").downcase.to_sym)
      events = EventSchedule.events_for_date(Date.current)
      expect(events).to be_present
    end
  end
end
