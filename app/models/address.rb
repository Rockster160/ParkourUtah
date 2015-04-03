class Address < ActiveRecord::Base
  # create_table "addresses", force: :cascade do |t|
  #   t.integer  "user_id"
  #   t.string   "line1"
  #   t.string   "line2"
  #   t.string   "city"
  #   t.string   "state"
  #   t.string   "zip"
  #   t.datetime "created_at", null: false
  #   t.datetime "updated_at", null: false
  # end

  belongs_to :user

  before_create :make_empty_fields

  def make_empty_fields
    self.line1 ||= ""
    self.line2 ||= ""
    self.city ||= ""
    self.state ||= ""
    self.zip ||= ""
  end
end
