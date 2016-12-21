# == Schema Information
#
# Table name: users
#
#  id                             :integer          not null, primary key
#  email                          :string           default(""), not null
#  first_name                     :string           default(""), not null
#  last_name                      :string           default(""), not null
#  encrypted_password             :string           default(""), not null
#  reset_password_token           :string
#  reset_password_sent_at         :datetime
#  remember_created_at            :datetime
#  sign_in_count                  :integer          default(0), not null
#  current_sign_in_at             :datetime
#  last_sign_in_at                :datetime
#  current_sign_in_ip             :inet
#  last_sign_in_ip                :inet
#  role                           :integer          default(0)
#  created_at                     :datetime
#  updated_at                     :datetime
#  avatar_file_name               :string
#  avatar_content_type            :string
#  avatar_file_size               :integer
#  avatar_updated_at              :datetime
#  avatar_2_file_name             :string
#  avatar_2_content_type          :string
#  avatar_2_file_size             :integer
#  avatar_2_updated_at            :datetime
#  bio                            :text
#  credits                        :integer          default(0)
#  phone_number                   :string
#  confirmation_token             :string
#  confirmed_at                   :datetime
#  confirmation_sent_at           :datetime
#  instructor_position            :integer
#  payment_multiplier             :integer          default(3)
#  stats                          :string
#  title                          :string
#  nickname                       :string
#  email_subscription             :boolean          default(TRUE)
#  stripe_id                      :string
#  date_of_birth                  :datetime
#  drivers_license_number         :string
#  drivers_license_state          :string
#  registration_complete          :boolean          default(FALSE)
#  registration_step              :integer          default(2)
#  stripe_subscription            :boolean          default(FALSE)
#  referrer                       :string           default("")
#  subscription_cost              :integer          default(5000)
#  unassigned_subscriptions_count :integer          default(0)
#

# Ununsed?
# first_name
# last_name
# email_subscription
# date_of_birth
# drivers_license_number
# drivers_license_state

class User < ActiveRecord::Base

  has_one :address, dependent: :destroy
  has_one :notifications, dependent: :destroy
  has_many :unlimited_subscriptions, dependent: :destroy
  has_many :carts, dependent: :destroy
  has_many :dependents, dependent: :destroy
  has_many :cart_items, through: :cart
  has_many :subscriptions, dependent: :destroy
  has_many :subscribed_events, through: :subscriptions, source: "event_schedule"
  has_many :classes_to_teach, class_name: "EventSchedule", foreign_key: "instructor_id"
  has_many :attendances_taught, class_name: "Attendance"
  has_many :emergency_contacts, dependent: :destroy

  after_create :assign_cart
  after_create :create_blank_address
  after_create :create_default_notifications
  after_create :send_welcome_email
  before_save :format_phone_number
  before_destroy :clear_associations

  devise :database_authenticatable, :registerable, :confirmable,
         :recoverable, :rememberable, :trackable, :validatable

  has_attached_file :avatar,
                    :styles => { :medium => "300x400>", :thumb => "120x160" },
                    storage: :s3,
                    bucket: ENV['PKUT_S3_BUCKET_NAME'],
                    :default_url => "/images/missing.png",
                    :convert_options => { :all => '-background white -flatten +matte' }
  validates_attachment_content_type :avatar, :content_type => /\Aimage\/.*\Z/

  has_attached_file :avatar_2,
                    :styles => { :medium => "300x400>", :thumb => "120x160" },
                    storage: :s3,
                    bucket: ENV['PKUT_S3_BUCKET_NAME'],
                    :default_url => "/images/missing.png",
                    :convert_options => { :all => '-background white -flatten +matte' }
  validates_attachment_content_type :avatar_2, :content_type => /\Aimage\/.*\Z/

  validate :valid_phone_number
  validate :positive_credits

  scope :online, -> { where('last_sign_in_at > ?', 10.minutes.ago) }
  scope :by_signed_in, -> { order(last_sign_in_at: :desc) }
  scope :by_fuzzy_text, lambda { |text|
    text = "%#{text}%"
    joins('LEFT OUTER JOIN dependents ON users.id = dependents.user_id')
      .where("email ILIKE ? OR concat(users.first_name, ' ', users.last_name) ILIKE ? OR CAST(users.id AS TEXT) ILIKE ? OR dependents.full_name ILIKE ? OR CAST(dependents.athlete_id AS TEXT) ILIKE ?", text, text, text, text, text).uniq
  }
  scope :instructors, -> { where("role > 0").order(:instructor_position) }
  scope :mods, -> { where("role > 1") }
  scope :admins, -> { where("role > 2") }

  def is_instructor?; role >= 1; end
  def is_mod?; role >= 2; end
  def is_admin?; role >= 3; end
  def self.[](id); find(id); end; #User[4]

  def self.last_signed_in
    by_signed_in.first
  end

  def self.every(&block)
    return self.all.to_enum unless block_given?
    self.all.each {|user| block.call(user)}
  end

  def self.remove_number_from_texting(num)
    if user = find_by_phone_number(num)
      user.notifications.update(sms_receivable: false)
      "Success!"
    else
      "Fail."
    end
  end

  def self.update_instructor_positions
    instructors.each_with_index do |instructor, pos|
      instructor.update(instructor_position: pos+1)
    end
  end

  def self.by_trial_expired_days_ago(days)
    users = []
    every do |user|
      has_expired_athlete = false
      user.athletes.each do |athlete|
        if athlete.created_at.to_date == (Time.now - days.days).to_date && !athlete.verified
          users << user
        end
      end
    end
    users
  end

  def still_signed_in!
    self.last_sign_in_at = Time.zone.now
    self.save!
  end

  def full_name
    "#{self.first_name.capitalize} #{self.last_name.capitalize}"
  end

  def signed_in?
    last_sign_in_at > 10.minutes.ago if last_sign_in_at
  end

  def athletes_with_unlimited_access
    athletes.joins(:athlete_subscriptions).where("athlete_subscriptions.expires_at > ?", Time.zone.now)
  end

  def subscribed_athletes
    athletes.joins(:athlete_subscriptions).where(athlete_subscriptions: { auto_renew: true })
  end

  def athlete_subscriptions
    athletes_with_unlimited_access.map(&:subscription).compact
  end

  def subscriptions_cost
    return 0 unless athlete_subscriptions

    athlete_subscriptions.inject(0) { |sum, subscription| sum + subscription.cost_in_pennies }
  end

  def emergency_numbers
    self.emergency_contacts.map { |num| format_phone_number_to_display(num) }
  end

  def athletes
    dependents
  end

  def non_verified_athletes
    dependents.select { |d| !(d.verified) }
  end

  def athletes_by_waiver_expiration
    dependents.sort_by { |d| d.waiver ? d.waiver.created_at : created_at }
  end

  def athletes_where_expired_past_or_soon
    dependents.select { |d| !(d.waiver) || d.waiver.expires_soon? || !(d.waiver.is_active?) }
  end

  def is_subscribed_to?(event_schedule_id)
    Subscription.where(user_id: self.id, event_schedule_id: event_schedule_id || 0).any?
  end

  def charge(price, athlete)
    if athlete.has_unlimited_access?
      athlete.subscription.use!
      'Unlimited Subscription'
    elsif athlete.has_trial?
      athlete.trial.use!
      'Trial Class'
    elsif self.credits >= price
      charge_credits(price)
    else
      return false
    end
  end

  def charge_credits(price)
    self.credits -= price
    send_alert_for_low_credits if self.credits < 30
    self.save!
  end

  def assign_cart
    self.carts.create
  end

  def create_blank_address
    self.address = Address.new
  end

  def create_default_notifications
    self.notifications ||= Notifications.new
  end

  def send_welcome_email
    SendWelcomeEmailWorker.perform_async(self.email)
  end

  def phone_number_is_valid?
    return false unless self.phone_number
    phone = self.phone_number.gsub(/[^\d]/, '')
    (phone.length == 10)
  end

  def cart
    self.carts.order(created_at: :desc).first
  end

  def show_phone_number
    format_phone_number_to_display(self.phone_number)
  end

  def show_address(str)
    self.address.show_address(str)
  end

  protected

  def send_alert_for_low_credits
    if self.notifications.email_low_credits
      ::LowCreditsMailerWorker.perform_async(self.id)
    end
    if self.notifications.text_low_credits && self.notifications.sms_receivable
      ::SmsMailerWorker.perform_async(self.phone_number, "You are low on Credits! Head up to ParkourUtah.com/store to get some more so you have some for next time.")
    end
  end

  def clear_associations
    self.carts.destroy_all
    self.address.destroy
  end

  def valid_phone_number
    return false unless self.phone_number
    phone = self.phone_number.gsub(/[^\d]/, '')
    unless phone.length == 10
      errors.add(:phone_number, "must have 10 digits.")
    end
    unless self.phone_number_is_valid?
      errors.add(:phone_number, "must be a valid phone number.")
    end
  end

  def format_phone_number
    self.phone_number = phone_number.gsub(/[^0-9]/, "") if attribute_present?("phone_number")
  end

  def format_phone_number_to_display(number)
    return "" unless number && number.length == 10
    "(#{number[0..2]}) #{number[3..5]}-#{number[6..9]}"
  end

  def split_name
    name = self.first_name.squish.split
    self.first_name = "#{name[0][0].capitalize}#{name[0][1..name[0].length]}"
    if name.count > 1
      self.last_name = "#{name[1][0].capitalize}#{name[1][1..name[1].length]}"
    end
  end

  def confirmation_required?
    false # Leave this- it bypasses Devise's confirmable method
  end

  def positive_credits
    if self.credits < 0
      errors.add(:credits, "cannot be negative.")
    end
  end

end
