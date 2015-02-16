class Cart < ActiveRecord::Base
  # create_table "carts", force: :cascade do |t|
  #   t.integer  "user_id"
  #   t.datetime "created_at", null: false
  #   t.datetime "updated_at", null: false
  # end
  # 
  # add_index "carts", ["user_id"], name: "index_carts_on_user_id", using: :btree

  belongs_to :user
  has_many :orders
end
