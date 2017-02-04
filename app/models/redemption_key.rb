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

class RedemptionKey < ApplicationRecord

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

  def item; self.line_item; end

  def generate_key
    caps = ('A'..'Z').to_a
    down = ('a'..'z').to_a
    nums = (0..9).to_a

    loop do
      key = 20.times.map {(caps + down + nums).sample}.join('')
      if RedemptionKey.where(key: key).count == 0
        self.update(key: key)
        break
      end
    end
  end

end
