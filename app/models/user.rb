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
  # end

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  has_attached_file :avatar,
                    :styles => { :medium => "300x300>", :thumb => "100x100#" },
                    :default_url => "/images/missing.png",
                    :convert_options => { :all => '-background white -flatten +matte' }
  validates_attachment_content_type :avatar, :content_type => /\Aimage\/.*\Z/

  has_attached_file :avatar_2,
                    :styles => { :medium => "300x300>", :thumb => "100x100#" },
                    :default_url => "/images/missing.png",
                    :convert_options => { :all => '-background white -flatten +matte' }
  validates_attachment_content_type :avatar_2, :content_type => /\Aimage\/.*\Z/

  def full_name
    "#{self.first_name.capitalize} #{self.last_name.capitalize}"
  end

  def is_mod?
    self.role > 0
  end

  def is_admin?
    self.role > 1
  end
end
