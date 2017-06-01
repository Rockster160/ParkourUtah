# == Schema Information
#
# Table name: redemption_keys
#
#  id                         :integer          not null, primary key
#  key                        :string
#  redemption                 :string
#  created_at                 :datetime         not null
#  updated_at                 :datetime         not null
#  redeemed                   :boolean          default(FALSE)
#  line_item_id               :integer
#  can_be_used_multiple_times :boolean          default(FALSE)
#

class RedemptionKey < ApplicationRecord

  after_create :generate_key
  belongs_to :line_item

  # LineItem.find(x).redemption_keys.create

  def self.redeem(key)
    key_to_redeem = self.where(key: key).first
    if key_to_redeem
      return true if key_to_redeem.try(:can_be_used_multiple_times?)
      return false if key_to_redeem.redeemed?
      key_to_redeem.update(redeemed: true)
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
