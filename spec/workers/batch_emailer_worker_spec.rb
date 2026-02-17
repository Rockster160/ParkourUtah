require 'rails_helper'

RSpec.describe BatchEmailerWorker do
  describe "#perform" do
    it "sends to specific email addresses" do
      expect {
        BatchEmailerWorker.new.perform("Subject", "<p>Body</p>", "test@example.com", "newsletter")
      }.to have_enqueued_mail(ApplicationMailer, :email)
    end

    it "sends to multiple comma-separated emails" do
      expect {
        BatchEmailerWorker.new.perform("Subject", "<p>Body</p>", "a@test.com, b@test.com", "newsletter")
      }.to have_enqueued_mail(ApplicationMailer, :email).twice
    end

    it "sends to users matching notification preference when no specific emails" do
      user = create(:user, can_receive_emails: true)
      user.notifications.update!(email_newsletter: true)

      expect {
        BatchEmailerWorker.new.perform("Subject", "<p>Body</p>", "", "newsletter")
      }.to have_enqueued_mail(ApplicationMailer, :email)
    end

    it "skips users who opted out of emails" do
      user = create(:user, can_receive_emails: false)

      expect {
        BatchEmailerWorker.new.perform("Subject", "<p>Body</p>", "", "newsletter")
      }.not_to have_enqueued_mail(ApplicationMailer, :email)
    end
  end
end
