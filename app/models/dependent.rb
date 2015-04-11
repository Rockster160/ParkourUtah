# == Schema Information
#
# Table name: dependents
#
#  id                         :integer          not null, primary key
#  user_id                    :integer
#  full_name                  :string
#  emergency_contact          :string
#  athlete_id                 :integer
#  athlete_pin                :integer
#  athlete_photo_file_name    :string
#  athlete_photo_content_type :string
#  athlete_photo_file_size    :integer
#  athlete_photo_updated_at   :datetime
#  created_at                 :datetime         not null
#  updated_at                 :datetime         not null
#  first_name                 :string
#  middle_name                :string
#  last_name                  :string
#  date_of_birth              :datetime
#

class Dependent < ActiveRecord::Base

  belongs_to :user
  has_many :waivers
  has_many :attendences

  has_attached_file :athlete_photo,
               :styles => { :medium => "300", :thumb => "100x100#" },
               storage: :s3,
               bucket: ENV['PKUT_S3_BUCKET_NAME'],
              #  :default_url => "/images/missing.png",
               :convert_options => { :all => '-background white -flatten +matte' }
  validates_attachment_content_type :athlete_photo, :content_type => /\Aimage\/.*\Z/

  before_save :fix_attributes

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

  def waiver
    self.waivers.sort_by(&:id).last
  end

  def emergency_phone
    format_phone(self.emergency_contact)
  end

  def guardian_phone
    format_phone(self.user.phone_number)
  end

  def format_phone(num)
    num ||= 0
    num = num.to_s.split('')
    number = []
    10.times { |t| number << (num[t].nil? ? "0" : num[t]) }
    "(#{number[0..2].join('')}) #{number[3..5].join('')}-#{number[6..9].join('')}"
  end

  def generate_pin
    self.sign_up_credits
    bads = []
    10.times do |t|
      bads << "666#{t}".to_i
      bads << "#{t}666".to_i
    end
    bads << ENV["PKUT_PIN"].to_i
    bads << Dependent.all.map { |user| user.athlete_id }
    self.athlete_id = ((0...9999).to_a - bads).sample
    self.save
  end

  def sign_up_credits
    self.user.update(credits: (self.user.credits + ENV["PKUT_CLASS_PRICE"].to_i))
  end

  private

  def fix_attributes
    format_name
    format_number
  end

  def format_name
    self.full_name = self.full_name.squish.split(' ').map(&:capitalize).join(' ')
  end

  def format_number
    self.emergency_contact = self.emergency_contact.gsub(/[^0-9]/, "")
  end

end
