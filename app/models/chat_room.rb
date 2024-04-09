# == Schema Information
#
# Table name: chat_rooms
#
#  id                       :integer          not null, primary key
#  name                     :string
#  visibility_level         :integer
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  message_type             :integer
#  last_message_received_at :datetime
#

class ChatRoom < ApplicationRecord
  include Defaults
  include ApplicationHelper

  has_many :chat_room_users, dependent: :destroy
  has_many :users, through: :chat_room_users
  has_many :messages,        dependent: :destroy

  after_create :add_chat_room_users

  default_on_create last_message_received_at: Time.zone.now

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
    chat: 1
  }

  validates_uniqueness_of :name, allow_nil: true

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

  def display_name(user=nil)
    if text?
      if support_user.present?
        support_user.display_name
      else
        format_phone_number(name)
      end
    else
      if name.present?
        name
      else
        if users.many?
          (users - [user].flatten).map(&:display_name).join(" & ")
        else
          users.map(&:display_name).join(" & ")
        end
      end
    end
  end

  def support_user
    return nil unless text?
    return nil unless name && name.gsub(/[^0-9]/, "").length == 10
    return User.by_phone_number(name).first
  end

  def unread_messages_for_user?(user)
    user.chat_room_users.where(chat_room_id: self.id, has_unread_messages: true).any?
  end

  def viewable_by_user?(user)
    chat_room_users.pluck(:user_id).include?(user.id) || user.admin?
  end

  def blacklisted?
    text? && (support_user.present? && !support_user.can_receive_sms?)
  end

  def last_message
    messages.order(created_at: :desc).first
  end

  def last_message_text
    last_message.try(:body) || "No Text"
  end

  def new_message!(message)
    update(last_message_received_at: message.created_at)
    return if text? && (message.from_instructor? || message.from_pkut?)
    (chat_room_users - [message.sent_from]).flatten.each { |chu| chu.update(has_unread_messages: true) }
  end

  private

  def add_chat_room_users
    if text?
      chat_room_users.find_or_create_by(user_id: support_user.id) if support_user.present?
      User.admins.each do |admin|
        chat_room_users.find_or_create_by(user_id: admin.id)
      end
    end
  end

end
