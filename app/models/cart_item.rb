# == Schema Information
#
# Table name: cart_items
#
#  id                       :integer          not null, primary key
#  amount                   :integer          default(1)
#  discount_cost_in_pennies :integer
#  discount_type            :text
#  order_name               :string
#  redeemed_token           :string           default("")
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  cart_id                  :integer
#  line_item_id             :integer
#  purchased_plan_item_id   :bigint
#

class CartItem < ApplicationRecord

  belongs_to :cart
  belongs_to :user, optional: true
  belongs_to :purchased_plan_item, optional: true
  belongs_to :line_item

  before_save :verify_amount_is_not_nil
  before_save :clamp_amount_to_redemption_limit

  def item; line_item; end

  def verify_amount_is_not_nil
    self.amount ||= 0
    self.redeemed_token ||= ""
    self.order_name ||= item.title
  end

  def redemption_key
    return if redeemed_token.blank?
    RedemptionKey.find_by(key: redeemed_token)
  end

  # Cap on this row's amount. nil means uncapped. A token we can't resolve back
  # to a key (deleted key, stale cart) stays locked at one, as it always was.
  def redemption_quantity_limit
    return if redeemed_token.blank?
    key = redemption_key
    return 1 unless key
    key.quantity_limit
  end

  def quantity_locked?
    redemption_quantity_limit == 1
  end

  # Enforced here rather than in the controller because /store/update_cart skips
  # CSRF and can be posted directly — the cap decides how many free/discounted
  # items and how many credits one code is worth at checkout.
  def clamp_amount_to_redemption_limit
    limit = redemption_quantity_limit
    return unless limit

    self.amount = amount.to_i.clamp(0, limit)
  end

  def discounted?
    discount_cost_in_pennies.present?
  end

  def discounted_cost
    return unless discounted?

    discount_cost_in_pennies / 100.to_f
  end
end
