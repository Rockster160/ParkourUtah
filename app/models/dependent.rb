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
#  verified                   :boolean          default(FALSE)
#

# TODO Rename to 'Athlete'
class Dependent < ApplicationRecord

  belongs_to :user
  has_many :waivers, dependent: :destroy
  has_many :trial_classes, dependent: :destroy
  has_many :athlete_subscriptions, dependent: :destroy
  has_many :attendances, dependent: :destroy

  has_attached_file :athlete_photo,
               :styles => { :medium => "300", :thumb => "100x100#" },
               storage: :s3,
               s3_permissions: :private,
               bucket: ENV['PKUT_S3_BUCKET_NAME'],
               :convert_options => { :all => '-background white -flatten +matte' }
  validates_attachment_content_type :athlete_photo, :content_type => /\Aimage\/.*\Z/

  before_save :fix_attributes

  def self.find_or_create_by_name_and_dob(param, user)
    name = param["name"]
    dob = param["dob"]
    athlete = Dependent.where(full_name: name.squish.split(' ').map(&:capitalize).join(' '), user_id: user.id).first
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

  def valid_athlete_pin?(check_athlete_pin)
    return false unless check_athlete_pin.present?
    self.athlete_pin == check_athlete_pin
  end

  def attend_class(event, instructor)
    attendance = nil
    charge_type = charge_class(event)
    if charge_type.present? && charge_type.is_a?(String)
      attendance = attendances.create(instructor_id: instructor.id, event_id: event.id, type_of_charge: charge_type)
    end
    attendance.try(:persisted?) || false
  end

  def charge_class(event)
    event_cost = event.cost_in_dollars.to_i
    if event.accepts_unlimited_classes? && has_unlimited_access?
      current_subscription.use! ? 'Unlimited Subscription' : false
    elsif event.accepts_trial_classes? && has_trial?
      use_trial! ? 'Trial Class' : false
    elsif user.credits >= event_cost
      user.charge_credits(event_cost) ? 'Credits' : false
    else
      false
    end
  end

  def trials
    trial_classes.where(used: false)
  end

  def has_trial?
    trials.any?
  end

  def trial
    trials.first
  end

  def use_trial!
    trial.try(:use!) || false
  end

  def has_unlimited_access?
    current_subscription.try(:active?) || false
  end

  def has_access_until
    athlete_subscriptions.active.order(:expires_at).last.expires_at
  end

  def subscribed?
    return false unless current_subscription

    current_subscription.auto_renew
  end

  def current_subscription
    athlete_subscriptions.active.order(:expires_at).last
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
    self.athlete_id = Dependent.pins_left.sample.to_i
    self.save
  end

  def self.pins_left
    bads = []
    10.times do |t|
      bads << "666#{t}".to_i
      bads << "#{t}666".to_i
    end
    bads << 0
    bads << ENV["PKUT_PIN"].to_i
    bads << Dependent.all.map { |user| user.athlete_id }
    ((0...9999).to_a - bads.flatten)
  end

  def self.athlete_id_tests(num)
    num.times do |n|
     athlete = Dependent.first
     athlete.generate_pin
    #  binding.pry if athlete.athlete_id == Dependent.last.athlete_id
     athlete.athlete_id
     puts n
   end
  end

  def sign_up_verified
    # self.user.update(credits: (self.user.credits + (ENV["PKUT_CLASS_PRICE"].to_i * 2)))
    2.times { self.trial_classes.create }
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
