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
  #   t.integer  "class_pass"
  # end

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable

  API_LOGIN = '34H962KteRF'.freeze # ENV['PKUT_AUTHNET_LOGIN']
  TRANSACTION_KEY = '92wavU3h45xZW88P'.freeze # ENV['PKUT_AUTHNET_TRANS_KEY']

  has_one :cart
  has_many :transactions, through: :cart

  after_create :create_AuthNet_profile, :assign_cart

  devise :database_authenticatable, :registerable,
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

  def full_name
    "#{self.first_name.capitalize} #{self.last_name.capitalize}"
  end

  def is_instructor?
    self.role > 0
  end

  def is_admin?
    self.role > 1
  end

  def get_AuthNet_token
    transaction = generate_AuthNet_transaction
    xml = "<customerProfileId>#{self.auth_net_id}</customerProfileId>
          <hostedProfileSettings>
          <setting>
          <settingName>hostedProfileValidationMode</settingName>
          <settingValue>testMode</settingValue>
          </setting>
          <setting>
          <settingName>hostedProfileReturnUrl</settingName>
          <settingValue>http://lvh.me:7545/users/edit</settingValue>
          </setting>
          <setting>
          <settingName>hostedProfileReturnUrlText</settingName>
          <settingValue>Back to Parkour Utah</settingValue>
          </setting>
          </hostedProfileSettings>"
    res = auth_net_xml_request('getHostedProfilePageRequest', xml)

    token = Hash.from_xml(res.body)["getHostedProfilePageResponse"]["token"]
  end

  def create_AuthNet_profile
    transaction = generate_AuthNet_transaction
    profile = AuthorizeNet::CIM::CustomerProfile.new(
      :email => self.email,
      :id => self.id
    )
    response = transaction.create_profile(profile)
    self.auth_net_id = response.profile_id
    self.save
  end

  def get_payment_id
    return payment_id if self.payment_id

    xml = "<customerProfileId>#{self.auth_net_id}</customerProfileId>"
    res = auth_net_xml_request('getCustomerProfileRequest', xml)

    self.payment_id = Hash.from_xml(res.body)["getCustomerProfileResponse"]["profile"]["paymentProfiles"]["customerPaymentProfileId"]
    self.save

    self.payment_id
  end

  def charge_class
    if self.class_pass > 0
      self.class_pass -= 1
      self.save
    else
      charge =
      "<lineItems>
      <itemId>CLASS</itemId>
      <name>Intermediate</name>
      <description>Charged for class</description>
      <quantity>1</quantity>
      <unitPrice>15</unitPrice>
      </lineItems>"
      charge_account(15, charge)
    end
  end

  def buy_shopping_cart
    items = ""
    line_items.each do |trans|
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

    auth_net_xml_request('createCustomerProfileTransactionRequest', xml)
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

    uri = URI('https://apitest.authorize.net/xml/v1/request.api')
    req = Net::HTTP::Post.new(uri.path)
    HTTParty.post(uri, body: xml, headers: { 'Content-Type' => 'application/xml' })
  end

  def generate_AuthNet_transaction
    AuthorizeNet::CIM::Transaction.new(
      API_LOGIN,
      TRANSACTION_KEY,
      # gateway: :live
      gateway: :sandbox
    )
  end

  def assign_cart
    self.cart = Cart.create
  end
end
