require 'rails_helper'

RSpec.describe CartItem, type: :model do
  describe "associations" do
    it { should belong_to(:cart) }
    it { should belong_to(:line_item) }
  end

  describe "redemption quantity cap" do
    let(:cart) { create(:cart) }
    let(:item) { create(:line_item, title: "3 Day Pass", cost_in_pennies: 0, credits: 3, category: "Class") }

    def redeemed_row(key, amount)
      CartItem.create!(cart: cart, line_item: item, redeemed_token: key.key, amount: amount)
    end

    it "holds a plain code to one unit" do
      key = create(:redemption_key, line_item: item)
      expect(redeemed_row(key, 4).amount).to eq(1)
    end

    it "allows up to max_quantity so one code can cover siblings" do
      key = create(:redemption_key, :covers_siblings, line_item: item)
      expect(redeemed_row(key, 2).amount).to eq(2)
    end

    it "clamps anything above max_quantity" do
      key = create(:redemption_key, :covers_siblings, line_item: item)
      expect(redeemed_row(key, 9).amount).to eq(2)
    end

    it "leaves multi-use keys uncapped" do
      key = create(:redemption_key, :multi_use, line_item: item)
      expect(redeemed_row(key, 5).amount).to eq(5)
    end

    it "does not cap rows that came from a normal purchase" do
      row = CartItem.create!(cart: cart, line_item: item, amount: 6)
      expect(row.amount).to eq(6)
    end

    it "locks a row whose key no longer exists" do
      key = create(:redemption_key, :covers_siblings, line_item: item)
      row = redeemed_row(key, 2)
      key.destroy

      row.update(amount: 2)
      expect(row.reload.amount).to eq(1)
    end

    it "clamps on update, not just create" do
      key = create(:redemption_key, :covers_siblings, line_item: item)
      row = redeemed_row(key, 1)

      row.update(amount: 7)
      expect(row.reload.amount).to eq(2)
    end
  end

  describe "#quantity_locked?" do
    let(:cart) { create(:cart) }
    let(:item) { create(:line_item) }

    it "is true for a single-unit code" do
      key = create(:redemption_key, line_item: item)
      row = CartItem.create!(cart: cart, line_item: item, redeemed_token: key.key, amount: 1)
      expect(row.quantity_locked?).to be true
    end

    it "is false when the code covers more than one athlete" do
      key = create(:redemption_key, :covers_siblings, line_item: item)
      row = CartItem.create!(cart: cart, line_item: item, redeemed_token: key.key, amount: 1)
      expect(row.quantity_locked?).to be false
    end

    it "is false for non-redemption rows" do
      row = CartItem.create!(cart: cart, line_item: item, amount: 1)
      expect(row.quantity_locked?).to be false
    end
  end
end
