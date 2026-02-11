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
end
