class Waiver < ActiveRecord::Base
  # create_table "waivers", force: :cascade do |t|
  #   t.integer  "dependent_id"
  #   t.boolean  "signed"
  #   t.string   "signed_for"
  #   t.string   "signed_by"
  #   t.datetime "created_at",        null: false
  #   t.datetime "updated_at",        null: false
  # end

  belongs_to :dependent

  def exp_date
    (self.created_at + 1.year - 1.day).strftime('%B %-d, %Y')
  end

  def is_active?
    true unless Date.today > self.exp_date
  end
end
