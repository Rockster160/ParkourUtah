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

  belongs_to :user
  has_one :waiver
  has_many :attendences

  has_attached_file :athlete_photo,
               :styles => { :medium => "300x400>", :thumb => "100x100#" },
               storage: :s3,
               bucket: ENV['PKUT_S3_BUCKET_NAME'],
              #  :default_url => "/images/missing.png",
               :convert_options => { :all => '-background white -flatten +matte' }
  validates_attachment_content_type :athlete_photo, :content_type => /\Aimage\/.*\Z/

  def signed_waiver?
    return false unless self.waiver
    self.waiver.signed?
  end

  def padded_pin
    str = ""
    (4 - self.athlete_id.to_s.length).times {str << "0"}
    str << self.athlete_id.to_s
    str
  end

  def generate_pin
    self.sign_up_credits
    self.athlete_id = ((0...9999).to_a - Dependent.all.map { |user| user.athlete_id }).sample
    self.save
  end

  def sign_up_credits
    self.user.update(credits: 12)
  end

  private

end
