class Address < ActiveRecord::Base
  # create_table "addresses", force: :cascade do |t|
  #   t.string   "line1"
  #   t.string   "line2"
  #   t.string   "city"
  #   t.string   "state"
  #   t.string   "zip"
  #   t.datetime "created_at", null: false
  #   t.datetime "updated_at", null: false
  # end
  
  belongs_to :user
end
