require 'rails_helper'

RSpec.describe Cart, type: :model do
  describe "associations" do
    it { should belong_to(:user).optional }
    it { should have_many(:cart_items).dependent(:destroy) }
  end

  describe "#price" do
    it "sums item costs" do
      user = create(:user)
      cart = user.cart
      item = create(:line_item, cost_in_pennies: 1000, credits: 0)
      cart.cart_items.create!(line_item: item, amount: 2, order_name: "Test")
      expect(cart.price).to eq(2000)
    end

    it "returns 0 for empty cart" do
      cart = create(:cart)
      expect(cart.price).to eq(0)
    end
  end

  describe "#shipping" do
    it "charges shipping for physical items" do
      user = create(:user)
      cart = user.cart
      shirt = create(:line_item, :clothing)
      cart.cart_items.create!(line_item: shirt, amount: 1, order_name: "Shirt")
      # 200 per item + 300 base
      expect(cart.shipping).to eq(500)
    end

    it "charges no shipping for classes" do
      user = create(:user)
      cart = user.cart
      item = create(:line_item, category: "Class")
      cart.cart_items.create!(line_item: item, amount: 1, order_name: "Class")
      expect(cart.shipping).to eq(0)
    end

    it "charges no shipping for gift cards" do
      user = create(:user)
      cart = user.cart
      gc = create(:line_item, :gift_card)
      cart.cart_items.create!(line_item: gc, amount: 1, order_name: "GC")
      expect(cart.shipping).to eq(0)
    end
  end

  describe "#taxes" do
    it "calculates 8.25% tax on taxable items" do
      user = create(:user)
      cart = user.cart
      item = create(:line_item, cost_in_pennies: 10000, taxable: true, credits: 0)
      cart.cart_items.create!(line_item: item, amount: 1, order_name: "Taxable")
      expect(cart.taxes).to eq(825) # 10000 * 0.0825
    end

    it "does not tax non-taxable items" do
      user = create(:user)
      cart = user.cart
      item = create(:line_item, cost_in_pennies: 10000, taxable: false, credits: 0)
      cart.cart_items.create!(line_item: item, amount: 1, order_name: "NonTaxable")
      expect(cart.taxes).to eq(0)
    end
  end

  describe "#total" do
    it "sums price + shipping + taxes" do
      user = create(:user)
      cart = user.cart
      item = create(:line_item, :clothing, cost_in_pennies: 2000)
      cart.cart_items.create!(line_item: item, amount: 1, order_name: "Shirt")
      expect(cart.total).to eq(cart.price + cart.shipping + cart.taxes)
    end
  end

  describe "dollar conversions" do
    it "converts price to dollars" do
      cart = create(:cart)
      allow(cart).to receive(:price).and_return(1550)
      expect(cart.price_in_dollars).to eq(15.50)
    end

    it "converts total to dollars" do
      cart = create(:cart)
      allow(cart).to receive(:total).and_return(2575)
      expect(cart.total_in_dollars).to eq(25.75)
    end
  end

  describe "#add_items" do
    it "adds new items to the cart" do
      user = create(:user)
      cart = user.cart
      item = create(:line_item)
      cart.add_items(item.id)
      expect(cart.cart_items.count).to eq(1)
      expect(cart.cart_items.first.amount).to eq(1)
    end

    it "increments existing item quantity" do
      user = create(:user)
      cart = user.cart
      item = create(:line_item)
      cart.add_items(item.id)
      cart.add_items(item.id)
      expect(cart.cart_items.count).to eq(1)
      expect(cart.cart_items.first.amount).to eq(2)
    end
  end

  describe "#is_physical?" do
    it "returns true when cart has clothing" do
      user = create(:user)
      cart = user.cart
      shirt = create(:line_item, :clothing)
      cart.cart_items.create!(line_item: shirt, amount: 1, order_name: "Shirt")
      expect(cart.is_physical?).to be true
    end

    it "returns false for class-only carts" do
      user = create(:user)
      cart = user.cart
      item = create(:line_item, category: "Class")
      cart.cart_items.create!(line_item: item, amount: 1, order_name: "Class")
      expect(cart.is_physical?).to be false
    end
  end

  describe "#is_gift_card?" do
    it "returns true when cart has gift card" do
      user = create(:user)
      cart = user.cart
      gc = create(:line_item, :gift_card)
      cart.cart_items.create!(line_item: gc, amount: 1, order_name: "GC")
      expect(cart.is_gift_card?).to be true
    end
  end
end
