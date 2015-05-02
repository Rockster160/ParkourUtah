# == Schema Information
#
# Table name: users
#
#  id                     :integer          not null, primary key
#  email                  :string           default(""), not null
#  first_name             :string           default(""), not null
#  last_name              :string           default(""), not null
#  encrypted_password     :string           default(""), not null
#  reset_password_token   :string
#  reset_password_sent_at :datetime
#  remember_created_at    :datetime
#  sign_in_count          :integer          default(0), not null
#  current_sign_in_at     :datetime
#  last_sign_in_at        :datetime
#  current_sign_in_ip     :inet
#  last_sign_in_ip        :inet
#  role                   :integer          default(0)
#  created_at             :datetime
#  updated_at             :datetime
#  avatar_file_name       :string
#  avatar_content_type    :string
#  avatar_file_size       :integer
#  avatar_updated_at      :datetime
#  avatar_2_file_name     :string
#  avatar_2_content_type  :string
#  avatar_2_file_size     :integer
#  avatar_2_updated_at    :datetime
#  bio                    :text
#  credits                :integer          default(0)
#  phone_number           :string
#  confirmation_token     :string
#  confirmed_at           :datetime
#  confirmation_sent_at   :datetime
#  instructor_position    :integer
#  payment_multiplier     :integer          default(3)
#  stats                  :string
#  title                  :string
#  nickname               :string
#  email_subscription     :boolean          default(TRUE)
#  stripe_id              :string
#  date_of_birth          :datetime
#  drivers_license_number :string
#  drivers_license_state  :string
#

class User < ActiveRecord::Base

  has_one :address, dependent: :destroy
  has_many :carts, dependent: :destroy
  has_many :dependents, dependent: :destroy
  has_many :transactions, through: :cart
  has_many :subscriptions, dependent: :destroy
  has_many :emergency_contacts, dependent: :destroy

  after_create :assign_cart
  after_create :create_blank_address
  after_create :send_welcome_email
  before_save :format_phone_number
  # before_save :split_name
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

  def self.[](id)
    self.find(id)
  end

  def full_name
    "#{self.first_name.capitalize} #{self.last_name.capitalize}"
  end

  def is_instructor?
    self.role >= 1
  end

  def is_mod?
    self.role >= 2
  end

  def is_admin?
    self.role >= 3
  end

  def emergency_numbers
    self.emergency_contacts.map { |num| format_phone_number_to_display(num) }
  end

  def subscribed?(event)
    Subscription.where(user_id: self.id, event_id: event.id).count > 0
  end

  def charge_credits(charge)
    if self.credits >= charge
      self.update(credits: self.credits - charge)
      self.save
      return true
    else
      return false
    end
  end

  def assign_cart
    self.carts.create
  end

  def create_blank_address
    self.address = Address.new
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
    self.carts.sort_by { |cart| cart.created_at }.last
  end

  protected

  def clear_associations
    self.carts.all.each { |cart| cart.destroy }
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

end
