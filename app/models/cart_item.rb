# == Schema Information
#
# Table name: cart_items
#
#  id             :integer          not null, primary key
#  cart_id        :integer
#  line_item_id   :integer
#  amount         :integer          default(1)
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  redeemed_token :string           default("")
#  order_name     :string
#

class CartItem < ApplicationRecord

  belongs_to :cart, optional: true
  belongs_to :user
  belongs_to :line_item, optional: true

  before_save :verify_amount_is_not_nil

  def item; line_item; end

  def verify_amount_is_not_nil
    self.amount ||= 0
    self.redeemed_token ||= ""
    self.order_name ||= item.title
  end

end
