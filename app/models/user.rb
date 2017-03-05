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
#  stats                          :string
#  title                          :string
#  nickname                       :string
#  can_receive_emails             :boolean          default(TRUE)
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
#  should_display_on_front_page   :boolean          default(TRUE)
#  can_receive_sms                :boolean          default(TRUE)
#  full_name                      :string
#

# Ununsed?
# first_name
# last_name
# date_of_birth
# drivers_license_number
# drivers_license_state
# reset_password_token
# confirmation_token
# stripe_id
# stripe_subscription
# subscription_cost
# unassigned_subscriptions_count

class User < ApplicationRecord
  extend ApplicationHelper
  include ApplicationHelper

  devise :database_authenticatable, :registerable, :confirmable,
         :recoverable, :rememberable, :trackable, :validatable

  LOW_CREDIT_ALERT = 30

  has_one  :address,                 dependent: :destroy
  has_one  :notifications,           dependent: :destroy

  has_many :recurring_subscriptions, dependent: :destroy
  has_many :carts,                   dependent: :destroy
  has_many :athletes,                dependent: :destroy
  has_many :event_subscriptions,     dependent: :destroy
  has_many :chat_room_users,         dependent: :destroy
  has_many :emergency_contacts,      dependent: :destroy
  has_many :cart_items,              through: :cart
  has_many :chat_rooms,              through: :chat_room_users

  has_many :classes_to_teach,   class_name: "EventSchedule", foreign_key: "instructor_id"
  has_many :attendances_taught, class_name: "Attendance",    foreign_key: "instructor_id"
  has_many :sent_messages,      class_name: "Message",       foreign_key: "sent_from_id"

  has_many :subscribed_events, through: :event_subscriptions, source: "event_schedule"

  accepts_nested_attributes_for :emergency_contacts
  accepts_nested_attributes_for :address
  accepts_nested_attributes_for :notifications

  before_validation { self.phone_number = strip_phone_number(self.phone_number) }
  after_create :assign_cart
  after_create :create_default_notifications
  after_create :send_welcome_email


  has_attached_file :avatar,
                    :styles => { :medium => "300x400>", :thumb => "120x160" },
                    storage: :s3,
                    s3_permissions: :private,
                    bucket: ENV['PKUT_S3_BUCKET_NAME'],
                    :default_url => "http://parkourutah.com/images/missing.png",
                    :convert_options => { :all => '-background white -flatten +matte' }
  validates_attachment_content_type :avatar, :content_type => /\Aimage\/.*\Z/

  has_attached_file :avatar_2,
                    :styles => { :medium => "300x400>", :thumb => "120x160" },
                    storage: :s3,
                    s3_permissions: :private,
                    bucket: ENV['PKUT_S3_BUCKET_NAME'],
                    :default_url => "http://parkourutah.com/images/missing.png",
                    :convert_options => { :all => '-background white -flatten +matte' }
  validates_attachment_content_type :avatar_2, :content_type => /\Aimage\/.*\Z/

  validate :valid_phone_number
  validate :positive_credits

  scope :online, -> { where('last_sign_in_at > ?', 10.minutes.ago) }
  scope :by_signed_in, -> { by_most_recent(:last_sign_in_at) }
  scope :by_fuzzy_text, lambda { |text|
    text = "%#{text}%"
    joins('LEFT OUTER JOIN athletes ON users.id = athletes.user_id')
      .where("email ILIKE ? OR concat(users.first_name, ' ', users.last_name) ILIKE ? OR CAST(users.id AS TEXT) ILIKE ? OR athletes.full_name ILIKE ? OR CAST(athletes.fast_pass_id AS TEXT) ILIKE ?", text, text, text, text, text).uniq
  }
  scope :by_phone_number, ->(number) { where("REGEXP_REPLACE(phone_number, '[^0-9]', '', 'g') ILIKE ?", "%#{strip_phone_number(number)}") }
  scope :instructors, -> { where("role > 0").order(:instructor_position) }
  scope :mods, -> { where("role > 1") }
  scope :admins, -> { where("role > 2") }

  def is_instructor?; role >= 1; end
  def is_mod?; role >= 2; end
  def is_admin?; role >= 3; end
  def instructor?; is_instructor?; end
  def mod?; is_mod?; end
  def admin?; is_admin?; end
  def self.[](id); find(id); end; #User[4]

  def self.last_signed_in
    by_signed_in.first
  end

  def self.remove_number_from_texting(num)
    if user = find_by_phone_number(num)
      user.notifications.update(can_receive_sms: false)
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

  def unsubscribe_from(notification_type)
    if notification_type.to_sym == :all
      notifications.change_all_email_to(false)
      notifications.save
    else
      notifications.update(notification_type.to_sym => false)
    end
  end

  def still_signed_in!
    self.last_sign_in_at = Time.zone.now
    self.save!(validate: false)
  end

  def display_name
    return nickname if nickname.present?
    return full_name if full_name.present?
    "User:#{id} - #{email}"
  end

  def signed_in?
    last_sign_in_at > 10.minutes.ago if last_sign_in_at
  end

  def athletes_with_unlimited_access
    athletes.joins(:recurring_subscriptions).where("recurring_subscriptions.expires_at > ?", Time.zone.now).distinct
  end

  def subscribed_athletes
    athletes_with_unlimited_access.where(recurring_subscriptions: { auto_renew: true })
  end

  def subscriptions_cost
    return 0 unless recurring_subscriptions

    recurring_subscriptions.map(&:cost_in_pennies).sum
  end

  def emergency_numbers
    self.emergency_contacts.map { |num| format_phone_number(num) }
  end

  def athletes_by_waiver_expiration
    athletes.sort_by { |athlete| athlete.waiver ? athlete.waiver.created_at : created_at }
  end

  def athletes_where_expired_past_or_soon
    athletes.select { |athlete| !(athlete.waiver) || athlete.waiver.expires_soon? || !(athlete.waiver.is_active?) }
  end

  def is_subscribed_to?(event_schedule_id)
    event_subscriptions.where(event_schedule_id: event_schedule_id).any?
  end

  def charge_credits(price)
    self.credits -= price
    send_alert_for_low_credits if self.credits < LOW_CREDIT_ALERT
    self.save!
  end

  def assign_cart
    self.carts.create
  end

  def update_notifications
    new_value = params[:sms_alert] ? true : false
  end

  def sms_alert; notifications.text_waiver_expiring?; end
  def sms_alert=(bool)
    notifications.assign_attributes(
      text_class_reminder: bool,
      text_class_cancelled: bool,
      text_low_credits: bool,
      text_waiver_expiring: bool
    )
  end

  def create_default_notifications
    self.notifications ||= Notifications.new({
      email_newsletter:      true,

      email_class_reminder:  true,
      email_low_credits:     true,
      email_waiver_expiring: true,
      email_class_cancelled: true,

      text_class_reminder:   false,
      text_low_credits:      false,
      text_waiver_expiring:  false,
      text_class_cancelled:  false
    })
  end

  def send_welcome_email
    ApplicationMailer.welcome_mail(self.email).deliver_later
  end

  def cart
    self.carts.order(created_at: :desc).first
  end

  def show_address(str)
    self.address.show_address(str)
  end

  protected

  def send_alert_for_low_credits
    if self.notifications.email_low_credits
      ApplicationMailer.low_credits_mail(self.id).deliver_later
    end
    if self.notifications.text_low_credits
      num = self.phone_number
      msg = "You are low on Credits! Head up to ParkourUtah.com/store to get some more so you have some for next time."
      Message.text.create(body: msg, chat_room_name: num, sent_from_id: 0).deliver
    end
  end

  def valid_phone_number
    return false unless self.registration_step > 2
    phone = self.phone_number.to_s.gsub(/[^\d]/, '')
    unless phone.length == 10
      errors.add(:phone_number, "must be a valid, 10 digit number.")
    end
  end

  def split_name
    name = self.first_name.squish.split
    self.first_name = "#{name[0][0].capitalize}#{name[0][1..name[0].length]}"
    if name.count > 1
      self.last_name = "#{name[1][0].capitalize}#{name[1][1..name[1].length]}"
    end
  end

  def positive_credits
    if self.credits < 0
      errors.add(:credits, "cannot be negative.")
    end
  end

  # Leave this- it bypasses Devise's confirmable method
  def confirmation_required?; false; end

end
