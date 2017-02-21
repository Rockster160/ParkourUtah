# == Schema Information
#
# Table name: chat_rooms
#
#  id               :integer          not null, primary key
#  name             :string
#  visibility_level :integer
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  message_type     :integer
#

class ChatRoom < ApplicationRecord
  include Defaults
  include ApplicationHelper
  has_many :chat_room_users
  has_many :users, through: :chat_room_users
  has_many :messages


  default_on_create visibility_level: 0 # admin
  enum visibility_level: {
    admin:      0,
    mod:        1,
    instructor: 2,
    global:     3,
    personal:   4
  }

  default_on_create message_type: 1 # chat
  enum message_type: {
    text: 0,
    chat: 1,
    contact_request: 2
  }

  validates_uniqueness_of :name

  scope :permitted_for_user, ->(user) {
    return none unless user.present?
    allowed_visibilities = []
    allowed_visibilities << :admin if user.admin?
    allowed_visibilities << :mod if user.mod?
    allowed_visibilities << :instructor if user.instructor?
    allowed_visibilities << :global
    allowed_visibility_ids = allowed_visibilities.map {|v| visibility_levels[v] }
    where(visibility_level: allowed_visibilities).distinct
  }
  scope :membered_by_user, ->(user) {
    return none unless user.present?
    joins(:chat_room_users).where(chat_room_users: { user_id: user.id }).distinct
  }
  scope :viewable_by_user, ->(user) {
    return none unless user.present?
    permitted_ids = permitted_for_user(user).pluck(:id)
    member_of_ids = membered_by_user(user).pluck(:id)
    where(id: (permitted_ids + member_of_ids).uniq)
  }

  def display_name
    if text?
      if support_user.present?
        "Support: #{support_user.display_name}"
      else
        "Support: #{format_phone_number(name)}"
      end
    else
      name
    end
  end

  def support_user
    return nil unless text?
    return nil unless name.gsub(/[^0-9]/, "").length == 10
    return User.by_phone_number(name).first
  end

  def last_message
    messages.order(created_at: :desc).first
  end

  def last_message_text
    last_message.try(:body) || "No Text"
  end

end
