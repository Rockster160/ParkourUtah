require 'rails_helper'

RSpec.describe Announcement, type: :model do
  describe "validations" do
    it { should validate_presence_of(:body) }
  end

  describe "#deliver" do
    it "sets delivered_at timestamp" do
      announcement = create(:announcement)
      expect(announcement.delivered_at).to be_nil
      announcement.deliver
      expect(announcement.reload.delivered_at).to be_present
    end
  end

  describe "#delivered?" do
    it "returns true when delivered" do
      announcement = create(:announcement, :delivered)
      expect(announcement.delivered?).to be true
    end

    it "returns false when not delivered" do
      announcement = create(:announcement)
      expect(announcement.delivered?).to be false
    end
  end

  describe ".current" do
    it "returns the most recently delivered, non-expired announcement" do
      old = create(:announcement, :delivered, delivered_at: 2.days.ago, expires_at: 1.week.from_now)
      current = create(:announcement, :delivered, delivered_at: 1.day.ago, expires_at: 1.week.from_now)
      _expired = create(:announcement, :delivered, delivered_at: 1.hour.ago, expires_at: 1.day.ago)
      _undelivered = create(:announcement, expires_at: 1.week.from_now)

      expect(Announcement.current).to eq(current)
    end

    it "returns nil when no current announcements" do
      expect(Announcement.current).to be_nil
    end
  end

  describe "#display" do
    it "converts bold markers to HTML" do
      announcement = build(:announcement, body: "This is *bold* text")
      expect(announcement.display).to include("<b>bold</b>")
    end

    it "converts tilde markers to red spans" do
      announcement = build(:announcement, body: "This is ~red~ text")
      expect(announcement.display).to include('class="announcement-red"')
    end

    it "converts plus markers to large spans" do
      announcement = build(:announcement, body: "This is +large+ text")
      expect(announcement.display).to include('class="announcement-large"')
    end

    it "converts link syntax to anchor tags" do
      announcement = build(:announcement, body: "(Click here)[https://example.com]")
      expect(announcement.display).to include('href="https://example.com"')
      expect(announcement.display).to include("Click here")
    end

    it "converts newlines to br tags" do
      announcement = build(:announcement, body: "Line 1\nLine 2")
      expect(announcement.display).to include("<br>")
    end
  end

  describe "#expires_at_date=" do
    it "parses date string" do
      announcement = build(:announcement)
      announcement.expires_at_date = "Jan 15, 2025"
      expect(announcement.expires_at.month).to eq(1)
      expect(announcement.expires_at.day).to eq(15)
    end
  end
end
