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

  def item; line_item; end

  def verify_amount_is_not_nil
    self.amount ||= 0
    self.redeemed_token ||= ""
    self.order_name ||= item.title
  end

  def discounted?
    discount_cost_in_pennies.present?
  end

  def discounted_cost
    return unless discounted?

    discount_cost_in_pennies / 100.to_f
  end
end
