# == Schema Information
#
# Table name: transactions
#
#  id             :integer          not null, primary key
#  cart_id        :integer
#  item_id        :integer
#  amount         :integer          default(1)
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  redeemed_token :string
#  order_name     :string
#

class Transaction < ActiveRecord::Base

  belongs_to :cart
  belongs_to :user

  before_save :verify_amount_is_not_nil

  def item
    LineItem.find(self.item_id)
  end

  def verify_amount_is_not_nil
    self.amount ||= 0
    self.redeemed_token ||= ""
    self.order_name ||= item.title
  end

end
