require 'rails_helper'

RSpec.describe Athlete, type: :model do
  describe "associations" do
    it { should belong_to(:user) }
    it { should have_many(:waivers).dependent(:destroy) }
    it { should have_many(:trial_classes).dependent(:destroy) }
    it { should have_many(:recurring_subscriptions).dependent(:destroy) }
    it { should have_many(:purchased_plan_items).dependent(:destroy) }
    it { should have_many(:attendances).dependent(:destroy) }
    it { should have_many(:competitors).dependent(:destroy) }
  end

  describe "name formatting" do
    it "titleizes full_name on save" do
      athlete = create(:athlete, full_name: "john doe")
      expect(athlete.full_name).to eq("John Doe")
    end

    it "squishes whitespace in name" do
      athlete = create(:athlete, full_name: "  john   doe  ")
      expect(athlete.full_name).to eq("John Doe")
    end
  end

  describe "#age" do
    it "calculates age from date_of_birth string" do
      dob = "01/15/2000"
      athlete = create(:athlete, date_of_birth: dob)
      expected = Date.current.year - 2000 - (Date.current < Date.new(Date.current.year, 1, 15) ? 1 : 0)
      expect(athlete.age).to eq(expected)
    end

    it "returns nil when no date_of_birth" do
      athlete = build(:athlete, date_of_birth: nil)
      expect(athlete.age).to be_nil
    end
  end

  describe "#youth? / #adult?" do
    it "returns youth for under 14" do
      athlete = create(:athlete, date_of_birth: "01/15/#{Date.current.year - 10}")
      expect(athlete.youth?).to be true
      expect(athlete.adult?).to be false
    end

    it "returns adult for 14 and over" do
      athlete = create(:athlete, date_of_birth: "01/15/2000")
      expect(athlete.adult?).to be true
    end
  end

  describe "#valid_fast_pass_pin?" do
    it "validates correct pin with zero-padding" do
      athlete = create(:athlete, fast_pass_pin: 42)
      expect(athlete.valid_fast_pass_pin?("0042")).to be true
      expect(athlete.valid_fast_pass_pin?(42)).to be true
    end

    it "rejects incorrect pin" do
      athlete = create(:athlete, fast_pass_pin: 1234)
      expect(athlete.valid_fast_pass_pin?("9999")).to be false
    end

    it "rejects blank pin" do
      athlete = create(:athlete, fast_pass_pin: 1234)
      expect(athlete.valid_fast_pass_pin?("")).to be false
      expect(athlete.valid_fast_pass_pin?(nil)).to be false
    end
  end

  describe "#waiver" do
    it "returns the most recently created waiver" do
      athlete = create(:athlete)
      old_waiver = create(:waiver, athlete: athlete, created_at: 2.days.ago)
      new_waiver = create(:waiver, athlete: athlete, created_at: 1.day.ago)
      expect(athlete.waiver).to eq(new_waiver)
    end
  end

  describe "#signed_waiver?" do
    it "returns true when waiver is signed" do
      athlete = create(:athlete)
      create(:waiver, :signed, athlete: athlete)
      expect(athlete.signed_waiver?).to be true
    end

    it "returns false when no waiver exists" do
      athlete = create(:athlete)
      expect(athlete.signed_waiver?).to be false
    end
  end

  describe "#generate_pin" do
    it "assigns a unique fast_pass_id" do
      athlete = create(:athlete, fast_pass_id: nil)
      athlete.generate_pin
      expect(athlete.reload.fast_pass_id).to be_present
      expect(athlete.fast_pass_id).to be_between(0, 9998)
    end
  end

  describe "#has_trial?" do
    it "returns true when unused trial classes exist" do
      athlete = create(:athlete)
      create(:trial_class, athlete: athlete)
      expect(athlete.has_trial?).to be true
    end

    it "returns false when all trials are used" do
      athlete = create(:athlete)
      create(:trial_class, :used, athlete: athlete)
      expect(athlete.has_trial?).to be false
    end
  end

  describe "#has_unlimited_access?" do
    it "returns true with active subscription" do
      athlete = create(:athlete)
      create(:recurring_subscription, :active, athlete: athlete, user: athlete.user)
      expect(athlete.has_unlimited_access?).to be true
    end

    it "returns false with expired subscription" do
      athlete = create(:athlete)
      create(:recurring_subscription, :expired, athlete: athlete, user: athlete.user)
      expect(athlete.has_unlimited_access?).to be false
    end
  end

  describe "scopes" do
    it ".verified returns only verified athletes" do
      verified = create(:athlete, verified: true)
      unverified = create(:athlete, verified: false)
      expect(Athlete.verified).to include(verified)
      expect(Athlete.verified).not_to include(unverified)
    end
  end

  describe "#relevant_plan" do
    let(:athlete) { create(:athlete) }
    let(:plan_item) { create(:plan_item) }
    let(:event) { create(:event) }

    def record_attendance_on(plan, free_item_index: 0, created_at: Time.current)
      attendance = create(:attendance, athlete: athlete, type_of_charge: "Plan", purchased_plan_item_id: plan.id)
      attendance.update_columns(created_at: created_at)
      plan.free_items[free_item_index]["attendance_ids"] ||= []
      plan.free_items[free_item_index]["attendance_ids"] << attendance.id
      plan.save!
      attendance
    end

    it "matches for a freshly assigned plan with no prior attendances" do
      plan = create(:purchased_plan_item, :active, user: athlete.user, athlete: athlete, plan_item: plan_item)
      matched_plan, matched_item = athlete.relevant_plan(event)
      expect(matched_plan).to eq(plan)
      expect(matched_item["tags"]).to include("classes")
    end

    it "does not match when the per-interval limit is already used up this week" do
      plan = create(:purchased_plan_item, :active, user: athlete.user, athlete: athlete, plan_item: plan_item)
      2.times { record_attendance_on(plan, created_at: Time.current) }
      expect(athlete.relevant_plan(event)).to be_nil
    end

    it "matches this week even after using the limit in a prior week (regression for cumulative-count bug)" do
      plan = create(:purchased_plan_item, :active, user: athlete.user, athlete: athlete, plan_item: plan_item)
      2.times { record_attendance_on(plan, created_at: 2.weeks.ago) }
      matched_plan, _ = athlete.relevant_plan(event)
      expect(matched_plan).to eq(plan)
    end

    it "matches this month for a monthly plan after using last month's allotment" do
      plan = create(:purchased_plan_item, :active, user: athlete.user, athlete: athlete, plan_item: plan_item)
      plan.update!(free_items: [{ "tags" => ["classes"], "count" => 5, "interval" => "month" }])
      5.times { record_attendance_on(plan, created_at: 5.weeks.ago) }
      matched_plan, _ = athlete.relevant_plan(event)
      expect(matched_plan).to eq(plan)
    end

    it "treats count: 0 as unlimited and matches no matter how many attendances exist" do
      plan = create(:purchased_plan_item, :active, user: athlete.user, athlete: athlete, plan_item: plan_item)
      plan.update!(free_items: [{ "tags" => ["classes"], "count" => 0, "interval" => "day" }])
      20.times { record_attendance_on(plan, created_at: Time.current) }
      matched_plan, matched_item = athlete.relevant_plan(event)
      expect(matched_plan).to eq(plan)
      expect(matched_item["count"].to_i).to eq(0)
    end
  end
end
