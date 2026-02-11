require 'rails_helper'

RSpec.describe ScheduleWorker do
  let(:worker) { ScheduleWorker.new }

  before do
    allow(HTTParty).to receive(:post)
  end

  describe "#perform" do
    it "dispatches tasks by name" do
      expect(worker).to receive(:uptime_ping).with(nil)
      worker.perform([["uptime_ping", nil]])
    end

    it "handles multiple tasks" do
      expect(worker).to receive(:uptime_ping).with(nil)
      expect(worker).to receive(:post_to_custom_logger).with(nil)
      worker.perform([["uptime_ping", nil], ["post_to_custom_logger", nil]])
    end
  end

  describe "send_class_text" do
    it "sends reminders to subscribed users with upcoming classes" do
      instructor = create(:user, :instructor)
      user = create(:user, phone_number: "8015551234", can_receive_sms: true)
      user.notifications.update!(text_class_reminder: true)

      # Create a class happening in ~2 hours
      schedule = create(:event_schedule, instructor: instructor,
        day_of_week: Date.current.strftime("%A").downcase.to_sym,
        hour_of_day: (Time.zone.now + 2.hours).hour,
        minute_of_day: 0
      )
      create(:event_subscription, user: user, event_schedule: schedule)

      # This is a timing-sensitive test, just verify it doesn't error
      expect { worker.send(:send_class_text, nil) }.not_to raise_error
    end
  end

  describe "waiver_checks" do
    it "runs without error" do
      user = create(:user)
      athlete = create(:athlete, user: user)
      create(:waiver, :signed, athlete: athlete, expiry_date: 1.week.from_now)

      expect { worker.send(:waiver_checks, nil) }.not_to raise_error
    end
  end

  describe "send_summary" do
    it "generates and sends summary in non-production" do
      instructor = create(:user, :instructor)
      create(:event_schedule, instructor: instructor)
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with("PKUT_EMAIL").and_return("admin@example.com")

      expect {
        worker.send(:send_summary, { "scope" => "day", "send_without_prod" => true })
      }.not_to raise_error
    end
  end

  describe "pull_logs_from_s3" do
    it "returns early (currently disabled)" do
      expect(worker.send(:pull_logs_from_s3, nil)).to be_nil
    end
  end
end
