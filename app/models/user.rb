class User < ActiveRecord::Base
  # create_table "users", force: :cascade do |t|
  #   t.string   "email",                  default: "", null: false
  #   t.string   "first_name",             default: "", null: false
  #   t.string   "last_name",              default: "", null: false
  #   t.string   "encrypted_password",     default: "", null: false
  #   t.string   "reset_password_token"
  #   t.datetime "reset_password_sent_at"
  #   t.datetime "remember_created_at"
  #   t.integer  "sign_in_count",          default: 0,  null: false
  #   t.datetime "current_sign_in_at"
  #   t.datetime "last_sign_in_at"
  #   t.inet     "current_sign_in_ip"
  #   t.inet     "last_sign_in_ip"
  #   t.integer  "role",                   default: 0
  #   t.datetime "created_at"
  #   t.datetime "updated_at"
  #   t.string   "avatar_file_name"
  #   t.string   "avatar_content_type"
  #   t.integer  "avatar_file_size"
  #   t.datetime "avatar_updated_at"
  #   t.string   "avatar_2_file_name"
  #   t.string   "avatar_2_content_type"
  #   t.integer  "avatar_2_file_size"
  #   t.datetime "avatar_2_updated_at"
  #   t.text     "bio"
  #   t.integer  "payment_id"
  #   t.integer  "credits"
  #   t.integer  "phone_number"
  #   t.integer  "instructor_position"
  #   t.integer  "payment_multiplier",    default: 3
  #   t.integer  "shipping_id"
  # end

  has_one :cart, dependent: :destroy
  has_one :address, dependent: :destroy
  has_many :dependents, dependent: :destroy
  has_many :transactions, through: :cart
  has_many :subscriptions, dependent: :destroy

  after_create :assign_cart
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
    self.cart = Cart.create
  end

  def phone_number_is_valid?
    return false unless self.phone_number
    phone = self.phone_number.gsub(/[^\d]/, '')
    (phone.length == 10)
  end

  protected

  def clear_associations
    self.cart.destroy
  end

  def valid_phone_number
    return false unless self.phone_number
    unless self.phone_number_is_valid? || self.phone_number.gsub(/[^\d]/, '').length == 0
      errors.add(:phone_number, "must be a valid phone number.")
    end
  end

  def format_phone_number
    self.phone_number = phone_number.gsub(/[^0-9]/, "") if attribute_present?("phone_number")
  end

  def confirmation_required?
    false # Leave this- it bypasses Devise's confirmable
  end

end
