class RedemptionKey < ActiveRecord::Base
  # t.string :key
  # t.string :redemption
  # t.boolean :redeemed

  after_create :generate_key

  # RedemptionKey.create(redemption: "free_class")

  def self.lookup(key)
    item = self.where(key: key).first
    return nil unless item && !(item.redeemed)
    case item.redemption
    when "free_class" then LineItem.find_by_title("Trial Class")
    when "scout_package" then LineItem.find_by_title("Scout Package")
    when "business_card" then LineItem.find_by_title("Trial Class")
    when "KSL" then LineItem.find_by_title("Trial Class")
    end
  end

  def self.redeem(key)
    item = self.where(key: key).first
    if item
      if item.redeemed
        return false
      else
        item.update(redeemed: true) if key
      end
    end
    true
  end

  def generate_key
    caps = ('A'..'Z').to_a
    down = ('a'..'z').to_a
    nums = (0..9).to_a

    key = 20.times.map {(caps + down + nums).sample}.join('')
    if RedemptionKey.all.where(key: key).count == 0
      self.update(key: key)
    end
  end

  def self.keys_created
    self.count
  end

  def self.keys_redeemed
    self.select { |key| key.redeemed }.count
  end
end
