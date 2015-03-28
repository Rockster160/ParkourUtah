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

  def price
    cost = 0
    self.transactions.each do |order|
      cost += (order.item.cost * order.amount)
    end
    cost
  end

  def items
    items = []
    self.transactions.each do |order|
      items <<  LineItem.find(order.item_id)
    end
    items
  end

end
