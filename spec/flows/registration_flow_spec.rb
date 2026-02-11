require 'rails_helper'

RSpec.describe "Registration Flow", type: :model do
  describe "new user and athlete setup" do
    it "creates user, athlete, waiver, and trial class" do
      # Step 1: User signs up (Devise handles this, we simulate post-signup)
      user = create(:user, registration_step: 2, phone_number: nil)

      # Step 2: Add phone number
      user.update!(phone_number: "8015551234", registration_step: 3)
      expect(user.phone_number).to eq("8015551234")

      # Step 3: Add athletes
      athlete = user.athletes.create!(full_name: "jimmy smith", date_of_birth: "03/15/2010")
      expect(athlete.full_name).to eq("Jimmy Smith") # titleized
      expect(athlete).to be_persisted

      # Step 4: Sign waiver
      waiver = athlete.waivers.create!(signed_for: "Jimmy Smith", signed_by: "Parent Name")
      expect(waiver).to be_valid
      waiver.sign!
      expect(waiver.signed).to be true
      expect(waiver.is_active?).to be true

      # Step 5: Generate PIN
      athlete.generate_pin
      expect(athlete.fast_pass_id).to be_present

      # Athlete gets a trial class
      athlete.sign_up_verified
      expect(athlete.trial_classes.count).to eq(1)
      expect(athlete.has_trial?).to be true

      # Verify default notifications were created
      expect(user.notifications).to be_present
      expect(user.notifications.email_newsletter).to be true

      # Verify cart was created
      expect(user.cart).to be_present
    end

    it "prevents waiver when name doesn't match athlete" do
      user = create(:user)
      athlete = create(:athlete, user: user, full_name: "John Doe")
      waiver = athlete.waivers.build(signed_for: "Jane Smith", signed_by: "Parent")
      expect(waiver).not_to be_valid
      expect(waiver.errors[:signed_for]).to be_present
    end
  end

  describe "athlete with multiple waivers" do
    it "uses the most recent waiver" do
      user = create(:user)
      athlete = create(:athlete, user: user)
      old_waiver = create(:waiver, athlete: athlete, created_at: 2.years.ago, expiry_date: 1.year.ago)
      new_waiver = create(:waiver, :signed, athlete: athlete)

      expect(athlete.waiver).to eq(new_waiver)
      expect(athlete.signed_waiver?).to be true
    end
  end

  describe "finding or creating athletes" do
    it "finds existing athlete by name and user" do
      user = create(:user)
      athlete = create(:athlete, user: user, full_name: "John Doe")

      found = Athlete.find_or_create_by_name_and_dob({ "name" => "John Doe", "dob" => "01/01/2000" }, user)
      expect(found).to eq(athlete)
    end

    it "creates new athlete when not found" do
      user = create(:user)
      result = Athlete.find_or_create_by_name_and_dob({ "name" => "New Person", "dob" => "06/15/2005" }, user)
      expect(result).to be_a(Athlete)
      expect(result).to be_persisted
      expect(result.full_name).to eq("New Person")
    end
  end
end
