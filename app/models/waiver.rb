class Waiver < ActiveRecord::Base
  # create_table "waivers", force: :cascade do |t|
  #   t.integer  "dependent_id"
  #   t.boolean  "signed"
  #   t.datetime "created_at",        null: false
  #   t.datetime "updated_at",        null: false
  # end

  belongs_to :dependent
end
