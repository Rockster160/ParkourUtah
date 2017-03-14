# == Schema Information
#
# Table name: messages
#
#  id            :integer          not null, primary key
#  sent_from_id  :integer
#  body          :text
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  read_at       :datetime
#  message_type  :integer
#  error         :boolean          default(FALSE)
#  error_message :string
#  chat_room_id  :integer
#

class Message < ApplicationRecord
  include ApplicationHelper
  attr_accessor :do_not_deliver
  belongs_to :chat_room
  belongs_to :sent_from, class_name: "User", optional: true
  # If sent_from_id is nil, message is from an unknown user.
  # If sent_from_id is 0, message is from PKUT

  before_validation :set_message_type_to_chat_room
  validates_presence_of :body

  after_create_commit :broadcast_creation
  after_create_commit :try_to_notify_of_unread_message
  after_create_commit { chat_room.new_message!(self) }

  scope :read, -> { where.not(read_at: nil) }
  scope :unread, -> { where(read_at: nil) }

  enum message_type: {
    text: 0,
    chat: 1
  }

  def from_pkut?; sent_from_id == 0; end
  def from_admin?; !!sent_from.try(:admin?); end
  def from_mod?; !!sent_from.try(:mod?); end
  def from_instructor?; !!sent_from.try(:instructor?); end
  def from_unknown_user?; sent_from_id.nil?; end

  def read!(time=Time.zone.now)
    update(read_at: time)
  end

  def read?; !read_at.nil?; end
  def unread?; read_at.nil?; end

  def error!(msg="")
    update(error: true, error_message: msg)
    ActionCable.server.broadcast "room_#{chat_room_id}_channel", error: { message_id: self.id, message: msg }
  end

  def from_instructor?
    return sent_from_id == 0 || !!sent_from.try(:instructor?)
  end

  def question?
    body.include?("?")
  end

  def sender_name
    return "ParkourUtah" if sent_from_id == 0
    display_name = (sent_from.try(:nickname) || sent_from.try(:full_name) || sent_from.try(:email))
    return display_name if display_name.present?
    if sent_from.present?
      "User #{sent_from_id}"
    else
      if chat_room.text?
        format_phone_number(chat_room.name)
      else
        "#{chat_room.name} User"
      end
    end
  end

  def chat_room_name=(name)
    formatted_name = name.to_s.gsub(/[^0-9]/, "")
    self.chat_room = ChatRoom.find_or_create_by(name: formatted_name, message_type: self.message_type)
  end

  def deliver
    if chat_room.try(:text?) && !chat_room.blacklisted?
      SmsMailerWorker.perform_async(chat_room.name, body)
    else
      error!("This user has Blacklisted ParkourUtah and cannot receive text messages from us.")
    end
  end

  def notify_slack
    phone_number = chat_room.name
    user_link = Rails.application.routes.url_helpers.admin_user_url(sent_from) if sent_from.present?
    opt_out = %w(STOP STOPALL UNSUBSCRIBE CANCEL END QUIT).include?(body.squish.upcase)
    slack_message = ""

    if opt_out
      sent_from.update(can_receive_sms: false) if sent_from.present? && sent_from.notifications.present?
      slack_message += "#{format_phone_number(phone_number)} has opted out of text messages from PKUT.\nThey will no longer receive text messages from us (Including messages sent from the admin text messaging page).\nIn order to re-enable messages, they must send a text message saying \"START\" to us, and then log in to their account, Home, then click Notifications, then the button that says 'Text Me!'\nIf the message sends successfully, they will be able to receive text messages from us again.\n"
    else
      escaped_body = body.split("\n").map { |line| "\n>#{line}" }.join("")
      slack_message += "*Received text message from: #{format_phone_number(phone_number)}*\n#{escaped_body}"
      respond_link = Rails.application.routes.url_helpers.chat_room_url(chat_room)
      slack_message += "\n<#{respond_link}|Click here to respond!>"
    end
    slack_message += sent_from.present? ? "\nPhone Number seems to match: <#{user_link}|#{sent_from.id} - #{sent_from.email}>" : ""
    channel = Rails.env.production? ? "#support" : "#slack-testing"
    SlackNotifier.notify(slack_message, channel)
  end

  private

  def try_to_notify_of_unread_message
    NotifyOfUnreadMessageWorker.perform_in(1.minute, self.id) unless do_not_deliver
  end

  def set_message_type_to_chat_room
    self.message_type = chat_room.try(:message_type)
  end

  def broadcast_creation
    rendered_message = MessagesController.render template: 'messages/index', locals: { messages: [self] }, layout: false
    ActionCable.server.broadcast "room_#{chat_room_id}_channel", message: rendered_message, current_user: nil
  end

end
