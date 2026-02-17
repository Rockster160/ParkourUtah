require 'rails_helper'

RSpec.describe LineItem, type: :model do
  describe "#cost_in_dollars" do
    it "converts pennies to dollars" do
      item = build(:line_item, cost_in_pennies: 2500)
      expect(item.cost_in_dollars).to eq(25.0)
    end
  end

  describe "#cost_in_dollars=" do
    it "converts dollars to pennies" do
      item = build(:line_item)
      item.cost_in_dollars = 25.00
      expect(item.cost_in_pennies).to eq(2500)
    end
  end

  describe "#cost_for" do
    it "calculates basic cost for quantity" do
      item = create(:line_item, cost_in_pennies: 1000)
      expect(item.cost_for(3)).to eq(3000)
    end

    it "applies bundle pricing when exceeding bundle amount" do
      item = create(:line_item, cost_in_pennies: 1000, bundle_amount: 5, bundle_cost_in_pennies: 700)
      expect(item.cost_for(5)).to eq(3500) # 700 * 5 instead of 1000 * 5
    end

    it "uses regular pricing below bundle threshold" do
      item = create(:line_item, cost_in_pennies: 1000, bundle_amount: 5, bundle_cost_in_pennies: 700)
      expect(item.cost_for(3)).to eq(3000)
    end
  end

  describe "#tax_for" do
    it "calculates 8.25% tax" do
      item = create(:line_item, cost_in_pennies: 10000, taxable: true)
      expect(item.tax_for(1)).to eq(825)
    end

    it "returns 0 for non-taxable items" do
      item = create(:line_item, cost_in_pennies: 10000, taxable: false)
      expect(item.tax_for(1)).to eq(0)
    end
  end

  describe "#exceeds_bundle?" do
    it "returns true when amount meets bundle threshold" do
      item = build(:line_item, bundle_amount: 3, bundle_cost_in_pennies: 500)
      expect(item.exceeds_bundle?(3)).to be true
      expect(item.exceeds_bundle?(5)).to be true
    end

    it "returns false when below bundle threshold" do
      item = build(:line_item, bundle_amount: 3, bundle_cost_in_pennies: 500)
      expect(item.exceeds_bundle?(2)).to be false
    end

    it "returns false when no bundle configured" do
      item = build(:line_item, bundle_amount: nil, bundle_cost_in_pennies: nil)
      expect(item.exceeds_bundle?(10)).to be false
    end
  end

  describe "#colors / #sizes" do
    it "splits comma-separated colors" do
      item = build(:line_item, color: "Red, Blue, Green")
      expect(item.colors).to eq(["Red", "Blue", "Green"])
    end

    it "splits comma-separated sizes" do
      item = build(:line_item, size: "S, M, L, XL")
      expect(item.sizes).to eq(["S", "M", "L", "XL"])
    end

    it "returns nil when no colors" do
      item = build(:line_item, color: nil)
      expect(item.colors).to be_nil
    end
  end

  describe "#tags=" do
    it "splits comma-separated tags and lowercases them" do
      item = build(:line_item)
      item.tags = "Classes, Intermediate, Outdoor"
      expect(item.tags).to eq(["classes", "intermediate", "outdoor"])
    end
  end

  describe "#discounted_cost_data" do
    it "returns discount data when user has matching plan" do
      user = create(:user)
      athlete = create(:athlete, user: user)
      plan_item = create(:plan_item)
      create(:purchased_plan_item, :active, user: user, athlete: athlete, plan_item: plan_item,
        discount_items: [{ "tags" => ["classes"], "discount" => "50%" }])
      item = create(:line_item, cost_in_pennies: 2000, tags: "classes")
      result = item.discounted_cost_data(user)
      expect(result).to be_present
      expect(result[:cost]).to eq(1000.0) # 50% off
    end

    it "returns nil when user has no matching plan" do
      user = create(:user)
      item = create(:line_item, cost_in_pennies: 2000, tags: "classes")
      expect(item.discounted_cost_data(user)).to be_nil
    end

    it "returns nil when item has no tags" do
      user = create(:user)
      item = create(:line_item, cost_in_pennies: 2000)
      expect(item.discounted_cost_data(user)).to be_nil
    end
  end
end
