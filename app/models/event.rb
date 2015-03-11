class Event < ActiveRecord::Base
  # create_table "events", force: :cascade do |t|
  #   t.datetime "date"
  #   t.integer  "token"
  #   t.string   "title"
  #   t.string   "host"
  #   t.float    "cost"
  #   t.text     "description"
  #   t.string   "city"
  #   t.string   "address"
  #   t.string   "location_instructions"
  #   t.string   "class_name"
  #   t.datetime "created_at",            null: false
  #   t.datetime "updated_at",            null: false
  # end

  has_many :attendences

  def host_by_id
    User.find(host)
  end

  def send_text
    ::SmsMailerWorker.perform_async('Ping!', ['3852599640'])
  end
end
