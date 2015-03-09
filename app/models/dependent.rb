class Dependent < ActiveRecord::Base
  # create_table "dependents", force: :cascade do |t|
  #   t.string   "full_name"
  #   t.integer  "emergency_contact"
  #   t.integer  "user_id"
  #   t.integer  "athlete_id"
  #   t.integer  "athlete_pin"
  #   t.string   "athlete_photo_file_name"
  #   t.string   "athlete_photo_content_type"
  #   t.integer  "athlete_photo_file_size"
  #   t.datetime "athlete_photo_updated_at"
  #   t.datetime "created_at",                 null: false
  #   t.datetime "updated_at",                 null: false
  # end

  # after_create :generate_pin - After waiver is signed

  belongs_to :user
  has_one :waiver
  has_many :attendences

  def signed_waiver?
    return false unless self.waiver
    self.waiver.signed?
  end

  def padded_pin
    str = ""
    (4 - self.athlete_id.to_s.length).times {|zero| str << "0"}
    str << self.athlete_id.to_s
    str
  end

  def generate_pin
    self.athlete_id = ((0...9999).to_a - Dependent.all.map { |user| user.athlete_id }).sample
    self.save
  end

  private

end
