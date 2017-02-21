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
  belongs_to :chat_room, touch: true
  belongs_to :sent_from, class_name: "User", optional: true
  # If sent_from is nil, assume phone_number group

  validates_presence_of :body

  after_create_commit { MessageBroadcastWorker.perform_async(self.id) }
  after_create_commit :try_to_notify_slack_of_unread_message

  scope :read, -> { where.not(read_at: nil) }
  scope :unread, -> { where(read_at: nil) }

  enum message_type: {
    text: 0,
    chat: 1,
    contact_request: 2
  }

  def read!(time=Time.zone.now)
    update(read_at: time)
  end

  def read?; !read_at.nil?; end
  def unread?; read_at.nil?; end

  def error!(msg="")
    update(error: true, error_message: msg)
    ActionCable.server.broadcast "phone_#{phone_number}_channel", error: { message_id: self.id, message: msg }
  end

  def from_instructor?
    return sent_from.try(:instructor?)
  end

  def sender_name
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

  def deliver
    # Messages receivable? Show before allowing an instructor to send a message
    # Add callback in the worker to show the message as errored, with the error.
    # (Enum? Or boolean with string?)
    SmsMailerWorker.perform_async(stripped_phone_number, body)
  end

  def notify_slack
    user_link = Rails.application.routes.url_helpers.admin_user_url(sent_from) if sent_from.present?
    opt_out = %w(STOP STOPALL UNSUBSCRIBE CANCEL END QUIT).include?(body.squish.upcase)
    slack_message = ""

    if opt_out
      sent_from.notifications.update(sms_receivable: false) if sent_from.present? && sent_from.notifications.present?
      slack_message += "#{format_phone_number(phone_number)} has opted out of text messages from PKUT.\nThey will no longer receive text messages from us (Including messages sent from the admin text messaging page).\nIn order to re-enable messages, they must send a text message saying \"START\" to us, and then log in to their account, Home, then click Notifications, then the button that says 'Text Me!'\nIf the message sends successfully, they will be able to receive text messages from us again.\n"
    else
      escaped_body = body.split("\n").map { |line| "\n>#{line}" }.join("")
      slack_message += "*Received text message from: #{format_phone_number(phone_number)}*\n#{escaped_body}"
      respond_link = Rails.application.routes.url_helpers.messages_url(phone_number: phone_number)
      slack_message += "\n<#{respond_link}|Click here to respond!>"
    end
    slack_message += sent_from.present? ? "\nPhone Number seems to match: <#{user_link}|#{sent_from.id} - #{sent_from.email}>" : ""
    channel = Rails.env.production? ? "#support" : "#slack-testing"
    SlackNotifier.notify(slack_message, channel)
  end

  private

  def try_to_notify_slack_of_unread_message
    if !sent_from.try(:instructor?) && self.text? && self.unread?
      NotifySlackOfUnreadMessageWorker.perform_in(20.seconds, self.id)
    end
  end

end
