require 'rails_helper'

RSpec.describe Waiver, type: :model do
  describe "associations" do
    it { should belong_to(:athlete) }
  end

  describe "defaults" do
    it "defaults signed to false" do
      waiver = Waiver.new
      expect(waiver.signed).to be false
    end

    it "defaults expiry_date to ~1 year from now" do
      waiver = Waiver.new
      expect(waiver.expiry_date).to be_within(2.days).of(1.year.from_now)
    end
  end

  describe "validation" do
    it "requires signed_for to match athlete name" do
      athlete = create(:athlete, full_name: "John Doe")
      waiver = build(:waiver, athlete: athlete, signed_for: "Jane Smith")
      expect(waiver).not_to be_valid
      expect(waiver.errors[:signed_for]).to include("Athlete name must match the one listed.")
    end

    it "is valid when signed_for matches athlete name" do
      athlete = create(:athlete, full_name: "John Doe")
      waiver = build(:waiver, athlete: athlete, signed_for: "John Doe")
      expect(waiver).to be_valid
    end

    it "is case-insensitive for name matching" do
      athlete = create(:athlete, full_name: "John Doe")
      waiver = build(:waiver, athlete: athlete, signed_for: "john doe")
      expect(waiver).to be_valid
    end
  end

  describe "#sign!" do
    it "marks the waiver as signed" do
      athlete = create(:athlete)
      waiver = create(:waiver, athlete: athlete)
      waiver.sign!
      expect(waiver.reload.signed).to be true
    end
  end

  describe "#is_active?" do
    it "returns true for signed, non-expired waiver" do
      athlete = create(:athlete)
      waiver = create(:waiver, :signed, athlete: athlete, expiry_date: 1.month.from_now)
      expect(waiver.is_active?).to be true
    end

    it "returns false for unsigned waiver" do
      athlete = create(:athlete)
      waiver = create(:waiver, athlete: athlete, signed: false, expiry_date: 1.month.from_now)
      expect(waiver.is_active?).to be false
    end

    it "returns false for expired waiver" do
      athlete = create(:athlete)
      waiver = create(:waiver, :signed, athlete: athlete, expiry_date: 1.day.ago)
      expect(waiver.is_active?).to be false
    end
  end

  describe "#expires_soon?" do
    it "returns true when within 8 days of expiry" do
      athlete = create(:athlete)
      waiver = create(:waiver, :signed, athlete: athlete, expiry_date: 5.days.from_now)
      expect(waiver.expires_soon?).to be true
    end

    it "returns false when expiry is far away" do
      athlete = create(:athlete)
      waiver = create(:waiver, :signed, athlete: athlete, expiry_date: 1.month.from_now)
      expect(waiver.expires_soon?).to be false
    end

    it "returns true when expiry_date is nil" do
      athlete = create(:athlete)
      waiver = create(:waiver, athlete: athlete)
      waiver.update_column(:expiry_date, nil)
      expect(waiver.expires_soon?).to be true
    end
  end
end
