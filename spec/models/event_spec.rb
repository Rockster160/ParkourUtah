require 'rails_helper'

RSpec.describe Event, type: :model do
  describe "associations" do
    it { should belong_to(:event_schedule) }
    it { should have_many(:attendances).dependent(:destroy) }
  end

  describe "validations" do
    it { should validate_presence_of(:date) }
  end

  describe "delegations" do
    let(:schedule) { create(:event_schedule, title: "Advanced", cost_in_pennies: 1500, city: "Provo") }
    let(:event) { create(:event, event_schedule: schedule) }

    it "delegates title from schedule" do
      expect(event.title).to eq("Advanced")
    end

    it "delegates cost_in_pennies from schedule" do
      expect(event.cost_in_pennies).to eq(1500)
    end

    it "delegates city from schedule" do
      expect(event.city).to eq("Provo")
    end
  end

  describe "#cancel! / #uncancel!" do
    it "cancels an event" do
      event = create(:event)
      event.cancel!
      expect(event.reload).to be_cancelled
    end

    it "uncancels an event" do
      event = create(:event, :cancelled)
      event.uncancel!
      expect(event.reload).not_to be_cancelled
    end
  end

  describe "#set_original_date" do
    it "stores the original date on initialize" do
      time = Time.zone.now
      event = Event.new(date: time, event_schedule: create(:event_schedule))
      expect(event.original_date).to eq(time)
    end
  end

  describe "#color_contrast" do
    let(:event) { create(:event) }

    it "returns black for light backgrounds" do
      expect(event.color_contrast("#FFFFFF")).to eq("#000")
    end

    it "returns white for dark backgrounds" do
      expect(event.color_contrast("#000000")).to eq("#FFF")
    end

    it "returns black for nil/missing color (defaults to white background)" do
      expect(event.color_contrast(nil)).to eq("#000")
    end
  end

  describe "#css_style" do
    it "includes background-color" do
      event = create(:event, event_schedule: create(:event_schedule, color: "#FF0000"))
      expect(event.css_style).to include("background-color: #FF0000")
    end
  end

  describe "scopes" do
    it ".in_the_future returns upcoming events" do
      future_event = create(:event, date: 1.day.from_now)
      past_event = create(:event, date: 1.day.ago)
      expect(Event.in_the_future).to include(future_event)
      expect(Event.in_the_future).not_to include(past_event)
    end
  end
end
