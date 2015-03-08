class Attendance < ActiveRecord::Base
  # create_table "attendances", force: :cascade do |t|
  #   t.integer  "dependent_id"
  #   t.integer  "instructor_id"
  #   t.integer  "event_id"
  #   t.string   "location"
  #   t.datetime "created_at",    null: false
  #   t.datetime "updated_at",    null: false
  # end

  belongs_to :dependent
  belongs_to :instructor
  belongs_to :event
end
