# == Schema Information
#
# Table name: athletes
#
#  id                         :integer          not null, primary key
#  user_id                    :integer
#  full_name                  :string
#  emergency_contact          :string
#  fast_pass_id               :integer
#  fast_pass_pin              :integer
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

##
# Unused?
#
# emergency_contact
# athlete_photo
# first_name
# middle_name
# last_name
class Athlete < ApplicationRecord

  belongs_to :user

  has_many :waivers,                 dependent: :destroy
  has_many :trial_classes,           dependent: :destroy
  has_many :recurring_subscriptions, dependent: :destroy
  has_many :attendances,             dependent: :destroy

  has_attached_file :athlete_photo,
               :styles => { :medium => "300", :thumb => "100x100#" },
               storage: :s3,
               s3_permissions: :private,
               bucket: ENV['PKUT_S3_BUCKET_NAME'],
               :convert_options => { :all => '-background white -flatten +matte' }
  validates_attachment_content_type :athlete_photo, :content_type => /\Aimage\/.*\Z/

  before_save :fix_attributes

  def self.pins_left
    bads = []
    10.times do |t|
      bads << "666#{t}".to_i
      bads << "#{t}666".to_i
    end
    bads << 0
    bads << ENV["PKUT_PIN"].to_i
    bads << Athlete.all.map { |user| user.fast_pass_id }
    ((0...9999).to_a - bads.flatten)
  end

  def self.find_or_create_by_name_and_dob(param, user)
    name = param["name"]
    dob = param["dob"]
    athlete = Athlete.where(full_name: name.squish.split(' ').map(&:capitalize).join(' '), user_id: user.id).first
    if athlete.nil?
      dob = format_dob(dob)
      athlete = if dob
        athlete = user.athletes.new(full_name: name, date_of_birth: dob)
        athlete.save ? athlete : nil
      else
        nil
      end
    end
    athlete
  end

  def valid_fast_pass_pin?(check_fast_pass_pin)
    return false unless check_fast_pass_pin.present?
    self.fast_pass_pin.to_s.rjust(4, "0") == check_fast_pass_pin.to_s.rjust(4, "0")
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
      use_subscription! ? 'Unlimited Subscription' : false
    elsif event.accepts_trial_classes? && has_trial?
      use_trial! ? 'Trial Class' : false
    elsif user.credits >= event_cost
      user.charge_credits(event_cost) ? 'Credits' : false
    else
      false
    end
  end

  def unused_trials
    trial_classes.where(used: false)
  end
  def has_trial?
    unused_trials.any?
  end
  def trial
    unused_trials.first
  end
  def use_trial!
    trial.try(:use!) || false
  end

  def has_unlimited_access?
    current_subscription.try(:active?) || false
  end
  def has_access_until
    current_subscription.try(:expires_at)
  end
  def subscribed?
    current_subscription.try(:auto_renew?) || false
  end
  def current_subscription
    recurring_subscriptions.active.by_most_recent(:expires_at).first
  end
  def use_subscription!
    current_subscription.try(:use!) || false
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

  def waiver
    waivers = self.waivers.group_by { |waiver| waiver.is_active? }[true]
    waivers ||= self.waivers
    waivers.by_most_recent(:created_at).first
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
    self.fast_pass_id = Athlete.pins_left.sample.to_i
    self.save
  end

  def sign_up_verified
    2.times { self.trial_classes.create }
  end

  private

  def fix_attributes
    format_name
    self.date_of_birth = Athlete.format_dob(self.date_of_birth)
  end

  def format_name
    self.full_name = self.full_name.squish.titleize
  end

  def self.format_dob(dob)
    dob
  end

end