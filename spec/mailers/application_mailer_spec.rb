require 'rails_helper'

RSpec.describe ApplicationMailer, type: :mailer do
  describe "#welcome_mail" do
    it "sends welcome email" do
      mail = ApplicationMailer.welcome_mail("test@example.com")
      expect(mail.to).to eq(["test@example.com"])
      expect(mail.subject).to eq("Thanks for signing up at ParkourUtah!")
    end
  end

  describe "#class_reminder_mail" do
    it "sends class reminder" do
      user = create(:user)
      mail = ApplicationMailer.class_reminder_mail(user.id, "Class at 5pm!")
      expect(mail.to).to eq([user.email])
      expect(mail.subject).to eq("Class Reminder")
    end
  end

  describe "#expiring_waiver_mail" do
    it "sends waiver expiration notice" do
      athlete = create(:athlete)
      mail = ApplicationMailer.expiring_waiver_mail(athlete.id)
      expect(mail.to).to eq([athlete.user.email])
      expect(mail.subject).to include("waiver expires soon")
    end
  end

  describe "#customer_purchase_mail" do
    it "sends order confirmation" do
      user = create(:user, :with_address)
      cart = user.cart
      item = create(:line_item, credits: 10)
      cart.cart_items.create!(line_item: item, amount: 1, order_name: item.title)
      cart.update!(purchased_at: Time.current)

      mail = ApplicationMailer.customer_purchase_mail(cart.id, user.email)
      expect(mail.to).to eq([user.email])
      expect(mail.subject).to eq("Order confirmation")
    end
  end

  describe "#low_credits_mail" do
    it "sends low credit warning" do
      user = create(:user)
      mail = ApplicationMailer.low_credits_mail(user.id)
      expect(mail.to).to eq([user.email])
      expect(mail.subject).to include("almost out of class credits")
    end
  end

  describe "#pin_reset_mail" do
    it "sends pin reset email" do
      athlete = create(:athlete)
      mail = ApplicationMailer.pin_reset_mail(athlete.id)
      expect(mail.to).to eq([athlete.user.email])
      expect(mail.subject).to include("Request for ID or Pin Reset")
    end
  end

  describe "#registered_competitor" do
    it "sends registration confirmation" do
      competitor = create(:competitor)
      mail = ApplicationMailer.registered_competitor(competitor.id)
      expect(mail.to).to eq([competitor.athlete.user.email])
      expect(mail.subject).to include("Registration complete")
    end
  end

  describe "#approved_competitor" do
    it "sends approval notice" do
      competitor = create(:competitor, :approved)
      mail = ApplicationMailer.approved_competitor(competitor.id)
      expect(mail.to).to eq([competitor.athlete.user.email])
      expect(mail.subject).to include("has been approved")
    end
  end

  describe "#new_athlete_info_mail" do
    it "sends new athlete info" do
      athlete = create(:athlete)
      mail = ApplicationMailer.new_athlete_info_mail([athlete.id])
      expect(mail.to).to eq([athlete.user.email])
      expect(mail.subject).to eq("New Athlete Information")
    end
  end

  describe "#help_mail" do
    it "sends contact form to admin" do
      params = { "name" => "John", "email" => "john@test.com", "phone" => "8015551234", "comment" => "Help!" }
      mail = ApplicationMailer.help_mail(params)
      expect(mail.subject).to eq("Request for Contact")
    end
  end

  describe "#public_mailer" do
    it "sends gift card email" do
      key = create(:redemption_key)
      mail = ApplicationMailer.public_mailer(key.id, "gift@example.com")
      expect(mail.to).to eq(["gift@example.com"])
      expect(mail.subject).to include("Gift Card")
    end
  end
end
