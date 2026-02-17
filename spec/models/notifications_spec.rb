require 'rails_helper'

RSpec.describe Notifications, type: :model do
  describe "associations" do
    it { should belong_to(:user) }
  end

  describe "#blow!" do
    it "disables all notifications with 'all'" do
      user = create(:user)
      notif = user.notifications
      notif.blow!("all")
      notif.reload
      expect(notif.email_newsletter).to be false
      expect(notif.email_class_reminder).to be false
      expect(notif.text_class_reminder).to be false
      expect(notif.text_low_credits).to be false
    end

    it "disables only text notifications with 'text'" do
      user = create(:user)
      notif = user.notifications
      notif.update!(text_class_reminder: true, text_low_credits: true)
      notif.blow!("text")
      notif.reload
      expect(notif.text_class_reminder).to be false
      expect(notif.text_low_credits).to be false
      expect(notif.email_newsletter).to be true # unchanged
    end

    it "disables only email notifications with 'email'" do
      user = create(:user)
      notif = user.notifications
      notif.blow!("email")
      notif.reload
      expect(notif.email_newsletter).to be false
      expect(notif.email_class_reminder).to be false
    end
  end

  describe "#change_all_email_to" do
    it "sets all email prefs to the given value" do
      user = create(:user)
      notif = user.notifications
      notif.change_all_email_to(false)
      expect(notif.email_newsletter).to be false
      expect(notif.email_class_reminder).to be false
      expect(notif.email_low_credits).to be false
      expect(notif.email_waiver_expiring).to be false
      expect(notif.email_class_cancelled).to be false
    end
  end

  describe "#change_all_text_to" do
    it "sets all text prefs to the given value" do
      user = create(:user)
      notif = user.notifications
      notif.change_all_text_to(true)
      expect(notif.text_class_cancelled).to be true
      expect(notif.text_class_reminder).to be true
      expect(notif.text_low_credits).to be true
      expect(notif.text_waiver_expiring).to be true
    end
  end
end
