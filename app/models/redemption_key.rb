class RedemptionKey < ActiveRecord::Base
  # t.string :key
  # t.string :redemption
  # t.boolean :redeemed

  after_create :generate_key

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
