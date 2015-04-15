# == Schema Information
#
# Table name: carts
#
#  id         :integer          not null, primary key
#  user_id    :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Cart < ActiveRecord::Base

  belongs_to :user
  has_many :transactions, dependent: :destroy

  def items
    items = []
    self.transactions.each do |order|
      items <<  LineItem.find(order.item_id)
    end
    items
  end

  def price
    cost = 0
    self.transactions.each do |order|
      cost += (order.item.cost * order.amount)
    end
    cost <= 0 ? 0 : cost
  end

  def shipping
    cost = 0
    self.transactions.each do |order|
      cost += (order.amount * 200) if !(order.item.category == "Class" || order.item.category == "Coupon")
    end
    cost += (cost > 0 ? 300 : 0)
    cost
  end

  def taxes
    cost = 0
    self.transactions.each do |order|
      cost += (order.item.tax * order.amount)
    end
    cost
  end

  def total
    self.price + self.shipping + self.taxes
  end

  def price_in_dollars
    (self.price.to_f / 100).round(2)
  end

  def shipping_in_dollars
    (self.shipping.to_f / 100).round(2)
  end

  def taxes_in_dollars
    (self.taxes.to_f / 100).round(2)
  end

  def total_in_dollars
    (self.total.to_f / 100).round(2)# <= 0 ? 0 : (self.total.to_f / 100).round(2)
  end

end
