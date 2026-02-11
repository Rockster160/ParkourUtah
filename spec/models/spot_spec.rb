require 'rails_helper'

RSpec.describe Spot, type: :model do
  describe "associations" do
    it { should have_many(:event_schedules) }
    it { should have_many(:images) }
    it { should have_many(:ratings) }
  end

  describe "validations" do
    it { should validate_presence_of(:lon) }
    it { should validate_presence_of(:lat) }
  end

  describe "#rating" do
    it "returns average of all ratings" do
      spot = create(:spot)
      create(:rating, spot: spot, rated: 4)
      create(:rating, spot: spot, rated: 2)
      expect(spot.rating).to eq(3.0)
    end

    it "returns 0 with no ratings" do
      spot = create(:spot)
      expect(spot.rating).to eq(0)
    end
  end

  describe "#rated" do
    it "returns count of ratings" do
      spot = create(:spot)
      create(:rating, spot: spot)
      create(:rating, spot: spot)
      expect(spot.rated).to eq(2)
    end
  end

  describe ".spot_titles" do
    it "returns all spot titles" do
      create(:spot, title: "Spot A")
      create(:spot, title: "Spot B")
      expect(Spot.spot_titles).to contain_exactly("Spot A", "Spot B")
    end
  end
end
