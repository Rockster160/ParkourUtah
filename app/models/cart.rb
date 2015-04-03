class Cart < ActiveRecord::Base
  # create_table "carts", force: :cascade do |t|
  #   t.integer  "user_id"
  #   t.datetime "created_at", null: false
  #   t.datetime "updated_at", null: false
  # end
  #
  # add_index "carts", ["user_id"], name: "index_carts_on_user_id", using: :btree

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
    cost
  end

  def shipping
    cost = 0
    self.transactions.each do |order|
      cost += (order.amount * 200) if order.item.category != "Class"
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
    cost = 0
    self.transactions.each do |order|
      cost += (order.item.cost * order.amount)
    end
    (cost.to_f / 100).round(2)
  end

  def shipping_in_dollars
    cost = 0
    self.transactions.each do |order|
      cost += (order.amount * 200) if order.item.category != "Class"
    end
    cost += (cost > 0 ? 300 : 0)
    (cost.to_f / 100).round(2)
  end

  def taxes_in_dollars
    cost = 0
    self.transactions.each do |order|
      cost += (order.item.tax * order.amount)
    end
    (cost.to_f / 100).round(2)
  end

  def total_in_dollars
    (self.total.to_f / 100).round(2)
  end

end
