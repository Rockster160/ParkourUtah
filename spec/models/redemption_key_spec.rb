require 'rails_helper'

RSpec.describe RedemptionKey, type: :model do
  describe "associations" do
    it { should belong_to(:line_item) }
  end

  describe "#generate_key" do
    it "auto-generates a 20-character key after creation" do
      item = create(:line_item)
      key = RedemptionKey.create!(line_item: item)
      expect(key.key).to be_present
      expect(key.key.length).to eq(20)
    end

    it "generates unique keys" do
      item = create(:line_item)
      keys = 5.times.map { RedemptionKey.create!(line_item: item).key }
      expect(keys.uniq.length).to eq(5)
    end
  end

  describe ".redeem" do
    it "marks a key as redeemed and returns true" do
      key = create(:redemption_key, expires_at: 1.year.from_now)
      result = RedemptionKey.redeem(key.key)
      expect(result).to be true
      expect(key.reload.redeemed).to be true
    end

    it "returns false for already-redeemed key" do
      key = create(:redemption_key, :redeemed, expires_at: 1.year.from_now)
      result = RedemptionKey.redeem(key.key)
      expect(result).to be false
    end

    it "allows multi-use keys to be redeemed repeatedly" do
      key = create(:redemption_key, :multi_use, expires_at: 1.year.from_now)
      result1 = RedemptionKey.redeem(key.key)
      result2 = RedemptionKey.redeem(key.key)
      expect(result1).to be true
      expect(result2).to be true
      expect(key.reload.redeemed).to be false # multi-use stays unredeemed
    end
  end

  describe "#expired?" do
    it "returns true for expired key" do
      key = build(:redemption_key, expires_at: 1.day.ago)
      expect(key.expired?).to be true
    end

    it "returns false for non-expired key" do
      key = build(:redemption_key, expires_at: 1.day.from_now)
      expect(key.expired?).to be false
    end

    it "returns false when no expiry date" do
      key = build(:redemption_key, expires_at: nil)
      expect(key.expired?).to be false
    end
  end

  describe "scopes" do
    it ".redeemable returns non-redeemed, non-expired keys" do
      good = create(:redemption_key, expires_at: 1.year.from_now)
      redeemed = create(:redemption_key, :redeemed, expires_at: 1.year.from_now)
      expired = create(:redemption_key, :expired)
      expect(RedemptionKey.redeemable).to include(good)
      expect(RedemptionKey.redeemable).not_to include(redeemed)
      expect(RedemptionKey.redeemable).not_to include(expired)
    end
  end

  describe "#expiry_date" do
    it "formats expires_at as string" do
      key = build(:redemption_key, expires_at: Time.zone.parse("2024-06-15"))
      expect(key.expiry_date).to eq("Jun 15, 2024")
    end

    it "returns nil when no expires_at" do
      key = build(:redemption_key, expires_at: nil)
      expect(key.expiry_date).to be_nil
    end
  end
end
