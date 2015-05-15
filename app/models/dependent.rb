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
#  date_of_birth              :string
#

class Dependent < ActiveRecord::Base

  belongs_to :user
  has_many :waivers

  has_attached_file :athlete_photo,
               :styles => { :medium => "300", :thumb => "100x100#" },
               storage: :s3,
               bucket: ENV['PKUT_S3_BUCKET_NAME'],
               :convert_options => { :all => '-background white -flatten +matte' }
  validates_attachment_content_type :athlete_photo, :content_type => /\Aimage\/.*\Z/

  before_save :fix_attributes

  def self.find_or_create_by_name_and_dob(param, user)
    name = param["name"]
    dob = param["dob"]
    athlete = Dependent.where(
                full_name: name.squish.split(' ').map(&:capitalize).join(' '),
                user_id: user.id
    ).first
    if athlete.nil?
      dob = format_dob(dob)
      athlete = if dob
        athlete = user.dependents.new(full_name: name, date_of_birth: dob)
        athlete.save ? athlete : nil
      else
        nil
      end
    end
    athlete
  end

  def attendances
    Attendance.where(dependent_id: athlete_id)
  end

  def signed_waiver?
    return false unless self.waiver
    self.waiver.signed?
  end

  def sign_waiver!
    return false unless self.waiver
    return true if signed_waiver?
    self.waiver.sign!
  end

  def zero_padded(num, digits)
    str = ""
    (digits.to_i - num.to_s.length).times {str << "0"}
    str << num.to_s
    str
  end

  def waiver
    waivers = self.waivers.group_by { |waiver| waiver.is_active? }[true]
    waivers ||= self.waivers
    waivers.sort_by(&:created_at).last
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
    self.user.update(credits: (self.user.credits + (ENV["PKUT_CLASS_PRICE"].to_i * 2)))
  end

  private

  def fix_attributes
    format_name
    self.date_of_birth = Dependent.format_dob(self.date_of_birth)
  end

  def format_name
    self.full_name = self.full_name.squish.split(' ').map(&:capitalize).join(' ')
  end

  def self.format_dob(dob)
    dob
  end

end
