require 'rails_helper'

RSpec.describe User, type: :model do
  describe "associations" do
    it { should have_one(:address).dependent(:destroy) }
    it { should have_one(:notifications).dependent(:destroy) }
    it { should have_many(:athletes).dependent(:destroy) }
    it { should have_many(:carts).dependent(:destroy) }
    it { should have_many(:recurring_subscriptions).dependent(:destroy) }
    it { should have_many(:event_subscriptions).dependent(:destroy) }
    it { should have_many(:emergency_contacts).dependent(:destroy) }
    it { should have_many(:purchased_plan_items) }
  end

  describe "callbacks" do
    it "creates a cart after creation" do
      user = create(:user)
      expect(user.carts.count).to eq(1)
    end

    it "creates default notifications after creation" do
      user = create(:user)
      expect(user.notifications).to be_present
      expect(user.notifications.email_newsletter).to be true
      expect(user.notifications.text_class_reminder).to be false
    end

    it "sends a welcome email after creation" do
      expect {
        create(:user)
      }.to have_enqueued_mail(ApplicationMailer, :welcome_mail)
    end

    it "strips phone number before validation" do
      user = create(:user, phone_number: "(801) 555-1234")
      expect(user.phone_number).to eq("8015551234")
    end
  end

  describe "validations" do
    it "requires a 10-digit phone number when registration_step > 2" do
      user = build(:user, phone_number: "123", registration_step: 3)
      expect(user).not_to be_valid
      expect(user.errors[:phone_number]).to include("must be a valid, 10 digit number.")
    end

    it "allows any phone number when registration_step <= 2" do
      user = build(:user, phone_number: nil, registration_step: 2)
      expect(user).to be_valid
    end

    it "does not allow negative credits" do
      user = build(:user, credits: -1)
      expect(user).not_to be_valid
      expect(user.errors[:credits]).to include("cannot be negative.")
    end
  end

  describe "roles" do
    it "identifies regular users" do
      user = build(:user, role: 0)
      expect(user.is_instructor?).to be false
      expect(user.is_mod?).to be false
      expect(user.is_admin?).to be false
    end

    it "identifies instructors" do
      user = build(:user, :instructor)
      expect(user.is_instructor?).to be true
      expect(user.is_mod?).to be false
    end

    it "identifies mods" do
      user = build(:user, :mod)
      expect(user.is_instructor?).to be true
      expect(user.is_mod?).to be true
      expect(user.is_admin?).to be false
    end

    it "identifies admins" do
      user = build(:user, :admin)
      expect(user.is_admin?).to be true
      expect(user.is_mod?).to be true
      expect(user.is_instructor?).to be true
    end
  end

  describe "#display_name" do
    it "returns nickname when present" do
      user = build(:user, nickname: "Flash")
      expect(user.display_name).to eq("Flash")
    end

    it "returns full_name when no nickname" do
      user = build(:user, nickname: nil, full_name: "Jane Doe")
      expect(user.display_name).to eq("Jane Doe")
    end

    it "returns email-based fallback when no nickname or full_name" do
      user = create(:user, nickname: nil, full_name: nil, first_name: "", last_name: "")
      expect(user.display_name).to include("User:")
    end
  end

  describe "#charge_credits" do
    it "deducts credits from the user" do
      user = create(:user, credits: 100)
      user.charge_credits(30)
      expect(user.reload.credits).to eq(70)
    end

    it "triggers low credit alert when below threshold" do
      user = create(:user, credits: 40)
      expect {
        user.charge_credits(15)
      }.to have_enqueued_mail(ApplicationMailer, :low_credits_mail)
    end
  end

  describe "#cart" do
    it "returns the most recent cart" do
      user = create(:user)
      old_cart = user.carts.first
      new_cart = user.carts.create
      expect(user.cart).to eq(new_cart)
    end
  end

  describe "#unsubscribe_from" do
    it "unsubscribes from a specific notification" do
      user = create(:user)
      user.unsubscribe_from(:email_newsletter)
      expect(user.notifications.reload.email_newsletter).to be false
    end

    it "unsubscribes from all email notifications" do
      user = create(:user)
      user.unsubscribe_from(:all)
      notifs = user.notifications.reload
      expect(notifs.email_newsletter).to be false
      expect(notifs.email_class_reminder).to be false
      expect(notifs.email_low_credits).to be false
    end
  end

  describe "scopes" do
    it ".instructors returns users with role > 0" do
      regular = create(:user)
      instructor = create(:user, :instructor)
      expect(User.instructors).to include(instructor)
      expect(User.instructors).not_to include(regular)
    end

    it ".admins returns users with role > 2" do
      instructor = create(:user, :instructor)
      admin = create(:user, :admin)
      expect(User.admins).to include(admin)
      expect(User.admins).not_to include(instructor)
    end

    it ".by_fuzzy_text matches by email" do
      user = create(:user, email: "findme@example.com")
      create(:user, email: "other@example.com")
      expect(User.by_fuzzy_text("findme")).to include(user)
    end
  end
end
