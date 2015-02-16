class Order < ActiveRecord::Base
  # create_table "orders", force: :cascade do |t|
  #   t.integer  "cart_id"
  #   t.integer  "item_id"
  #   t.datetime "created_at", null: false
  #   t.datetime "updated_at", null: false
  # end
  #
  # add_index "orders", ["cart_id"], name: "index_orders_on_cart_id", using: :btree

  belongs_to :cart
end
