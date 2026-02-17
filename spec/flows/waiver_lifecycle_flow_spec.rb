require 'rails_helper'

RSpec.describe "Waiver Lifecycle Flow", type: :model do
  describe "complete waiver lifecycle" do
    it "creates waiver, signs it, tracks expiration, and renews" do
      user = create(:user)
      athlete = create(:athlete, user: user, full_name: "Test Runner")

      # Step 1: Create waiver
      waiver = athlete.waivers.create!(signed_for: "Test Runner", signed_by: "Parent Name")
      expect(waiver.signed).to be false
      expect(waiver.expiry_date).to be > 11.months.from_now

      # Step 2: Sign waiver
      waiver.sign!
      expect(waiver.signed).to be true
      expect(waiver.is_active?).to be true
      expect(waiver.expires_soon?).to be false

      # Step 3: Time passes, waiver expires soon
      waiver.update_column(:expiry_date, 5.days.from_now)
      expect(waiver.expires_soon?).to be true
      expect(waiver.is_active?).to be true # still active

      # Step 4: Waiver expires
      waiver.update_column(:expiry_date, 1.day.ago)
      expect(waiver.is_active?).to be false

      # Step 5: Renew by creating new waiver
      new_waiver = athlete.waivers.create!(signed_for: "Test Runner", signed_by: "Parent Name")
      new_waiver.sign!
      expect(athlete.waiver).to eq(new_waiver)
      expect(athlete.signed_waiver?).to be true
    end
  end

  describe "user athletes with expiring waivers" do
    it "finds athletes with expired or expiring waivers" do
      user = create(:user)
      healthy = create(:athlete, user: user, full_name: "Healthy Athlete")
      create(:waiver, :signed, athlete: healthy, expiry_date: 6.months.from_now)

      expiring = create(:athlete, user: user, full_name: "Expiring Athlete")
      create(:waiver, :signed, athlete: expiring, expiry_date: 5.days.from_now)

      expired = create(:athlete, user: user, full_name: "Expired Athlete")
      create(:waiver, :signed, athlete: expired, expiry_date: 1.day.ago)

      no_waiver = create(:athlete, user: user, full_name: "No Waiver")

      at_risk = user.athletes_where_expired_past_or_soon
      expect(at_risk).to include(expiring, expired, no_waiver)
      expect(at_risk).not_to include(healthy)
    end
  end
end
