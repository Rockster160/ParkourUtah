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
  #   t.integer  "auth_net_id"
  #   t.integer  "payment_id"
  #   t.integer  "credits"
  #   t.integer  "phone_number"
  #   t.integer  "instructor_position"
  #   t.integer  "payment_multiplier",    default: 3
  # end

  if ENV["RAILS_ENV"] == "production"
    API_LOGIN = ENV['PKUT_AUTHNET_LOGIN'].freeze
    TRANSACTION_KEY = ENV['PKUT_AUTHNET_TRANS_KEY'].freeze
  else
    API_LOGIN = '34H962KteRF'.freeze
    TRANSACTION_KEY = '92wavU3h45xZW88P'.freeze
  end

  has_one :cart
  has_many :dependents
  has_many :transactions, through: :cart
  has_many :subscriptions

  after_create :create_AuthNet_profile, :assign_cart
  before_save :format_phone_number

  devise :database_authenticatable, :registerable, :confirmable,
         :recoverable, :rememberable, :trackable, :validatable

  has_attached_file :avatar,
                    :styles => { :medium => "300x300>", :thumb => "100x100#" },
                    storage: :s3,
                    bucket: ENV['PKUT_S3_BUCKET_NAME'],
                    :default_url => "/images/missing.png",
                    :convert_options => { :all => '-background white -flatten +matte' }
  validates_attachment_content_type :avatar, :content_type => /\Aimage\/.*\Z/

  has_attached_file :avatar_2,
                    :styles => { :medium => "300x300>", :thumb => "100x100#" },
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
    self.role > 0
  end

  def is_mod?
    self.role > 1
  end

  def is_admin?
    self.role > 2
  end

  def subscribed?(event)
    Subscription.where(user_id: self.id, event_id: event).count > 0
  end

  def get_AuthNet_token
    return 0000 unless create_AuthNet_profile
    transaction = generate_AuthNet_transaction
    return_url = if ENV["RAILS_ENV"] == "production"
      "http://localhost:7545"
    else
      "http:45.55.180.23" #FIXME
    end
    xml =
    "<customerProfileId>#{self.auth_net_id}</customerProfileId>
    <hostedProfileSettings>
    <setting>
    <settingName>hostedProfileValidationMode</settingName>
    <settingValue>testMode</settingValue>
    </setting>
    <setting>
    <settingName>hostedProfileReturnUrl</settingName>
    <settingValue>#{return_url}/peeps/return</settingValue>
    </setting>
    <setting>
    <settingName>hostedProfileReturnUrlText</settingName>
    <settingValue>Back to Parkour Utah</settingValue>
    </setting>
    </hostedProfileSettings>"
    res = auth_net_xml_request('getHostedProfilePageRequest', xml)

    token = Hash.from_xml(res.body)["getHostedProfilePageResponse"]["token"] unless res == 0000
  end

  def has_auth_net_billing
  end

  def create_AuthNet_profile
    return true if self.auth_net_id
    transaction = generate_AuthNet_transaction
    profile = AuthorizeNet::CIM::CustomerProfile.new(
      :email => self.email,
      :id => self.id
    )
    response = transaction.create_profile(profile)
    self.auth_net_id = response.profile_id
    self.save
  end

  def delete_all_AuthNet
    ((31931699..31931710).to_a + []).each do |user|
      xml = "<customerProfileId>#{user}</customerProfileId>"
      res = auth_net_xml_request('deleteCustomerProfileRequest', xml)
      print "\e[31m.\e[0m"
    end
  end

  def get_payment_id
    return 0000 unless create_AuthNet_profile
    return payment_id if self.payment_id

    xml = "<customerProfileId>#{self.auth_net_id}</customerProfileId>"
    res = auth_net_xml_request('getCustomerProfileRequest', xml)

    self.payment_id = Hash.from_xml(res.body)["getCustomerProfileResponse"]["profile"]["paymentProfiles"]["customerPaymentProfileId"] unless res == 0000
    self.save

    self.payment_id
  end

  def charge_credits(price)
    if self.credits >= price
      self.update(credits: self.credits - price)
      self.save
      return true
    else
      return false
    end
  end

  def buy_shopping_cart
    return "Ok" if self.cart.price <= 0
    return 0000 unless create_AuthNet_profile
    order = self.cart.transactions
    items = ""
    order.each do |trans|
      item = trans.item
      items <<
      "<lineItems>
      <itemId>#{item.id}</itemId>
      <name>#{item.title}</name>
      <description>#{item.description}</description>
      <quantity>#{trans.amount}</quantity>
      <unitPrice>#{item.cost}</unitPrice>
      </lineItems>"
    end
    charge_account(self.cart.price, items)
  end

  def charge_account(cost, line_items)
    xml =
    "<transaction>
    <profileTransAuthCapture>
    <amount>#{cost}</amount>
    #{line_items}
    <customerProfileId>#{self.auth_net_id}</customerProfileId>
    <customerPaymentProfileId>#{self.get_payment_id}</customerPaymentProfileId>
    </profileTransAuthCapture>
    </transaction>"

    res = auth_net_xml_request('createCustomerProfileTransactionRequest', xml)
    Hash.from_xml(res.body)["createCustomerProfileTransactionResponse"]["messages"]["resultCode"] unless res == 0000
  end

  def auth_net_xml_request(title, mini_xml)
    xml =
    "<?xml version='1.0' encoding='utf-8'?>
    <#{title} xmlns='AnetApi/xml/v1/schema/AnetApiSchema.xsd'>
    <merchantAuthentication>
    <name>#{API_LOGIN}</name>
    <transactionKey>#{TRANSACTION_KEY}</transactionKey>
    </merchantAuthentication>
    #{mini_xml}
    </#{title}>"

    if ENV["RAILS_ENV"] == "production"
      uri = URI('https://api.authorize.net/xml/v1/request.api')
    else
      uri = URI('https://apitest.authorize.net/xml/v1/request.api')
    end
    req = Net::HTTP::Post.new(uri.path)
    begin
      HTTParty.post(uri, body: xml, headers: { 'Content-Type' => 'application/xml' })
    rescue Errno::ECONNREFUSED
      0000
    rescue Errno::ETIMEDOUT
      0000
    end
  end

  def generate_AuthNet_transaction
    gateway_env = ENV["RAILS_ENV"] == "production" ? :live : :sandbox
    AuthorizeNet::CIM::Transaction.new(
      API_LOGIN,
      TRANSACTION_KEY,
      gateway: gateway_env
    )
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

  def valid_phone_number
    return false unless self.phone_number
    unless self.phone_number_is_valid? || self.phone_number.gsub(/[^\d]/, '').length == 0
      errors.add(:phone_number, "must be a valid phone number.")
    end
  end

  def confirmation_required?
    false
  end

  def format_phone_number
    self.phone_number = phone_number.gsub(/[^0-9]/, "") if attribute_present?("phone_number")
  end

end
