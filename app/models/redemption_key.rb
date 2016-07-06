# == Schema Information
#
# Table name: redemption_keys
#
#  id           :integer          not null, primary key
#  key          :string
#  redemption   :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  redeemed     :boolean          default(FALSE)
#  line_item_id :integer
#

class RedemptionKey < ActiveRecord::Base

  after_create :generate_key
  belongs_to :line_item

  # LineItem.find(x).redemption_keys.create

  def self.redeem(key)
    item = self.where(key: key).first
    if item
      if item.redeemed
        return false
      else
        item.update(redeemed: true)
      end
    end
    true
  end

  def item
    self.line_item || LineItem.first
  end

  def generate_key
    caps = ('A'..'Z').to_a
    down = ('a'..'z').to_a
    nums = (0..9).to_a

    key = 20.times.map {(caps + down + nums).sample}.join('')
    if RedemptionKey.where(key: key).count == 0
      self.update(key: key)
    else
      self.generate_key
    end
  end

  def self.keys_created
    self.count
  end

  def self.keys_redeemed
    self.select { |key| key.redeemed }.count
  end

end
