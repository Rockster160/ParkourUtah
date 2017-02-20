# == Schema Information
#
# Table name: messages
#
#  id                    :integer          not null, primary key
#  sent_from_id          :integer
#  stripped_phone_number :string
#  body                  :text
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  sent_to_id            :integer
#  read_at               :datetime
#  message_type          :integer
#  error                 :boolean          default(FALSE)
#  error_message         :string
#

class Message < ActiveRecord::Base
  belongs_to :sent_from, class_name: "User", optional: true
  belongs_to :sent_to, class_name: "User", optional: true

  before_validation :remove_non_digits_from_db_phone_number
  before_validation :assign_users
  validate :phone_number_length
  validates_presence_of :body

  after_create_commit { MessageBroadcastWorker.perform_async(self.id) }
  after_create_commit :try_to_notify_slack_of_unread_message

  scope :by_phone_number, ->(phone_number) { where("REGEXP_REPLACE(stripped_phone_number, '[^0-9]', '', 'g') ILIKE ?", "%#{strip_phone_number(phone_number).last(10)}") }
  scope :sent_and_received_by_user, ->(user) { where("sent_from_id = :user_id OR sent_to_id = :user_id", user_id: user.id) }
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

  def lookup_receiver_by_phone_number
    User.by_phone_number(phone_number).first
  end

  def sender_name
    display_name = (sent_from.try(:nickname) || sent_from.try(:full_name) || sent_from.try(:email))
    return display_name if display_name.present?
    if sent_from.present?
      "User #{sent_from_id}"
    else
      stripped_phone_number
    end
  end

  def receiver_name
    display_name = (sent_from.try(:nickname) || sent_from.try(:full_name) || sent_from.try(:email))
    return display_name if display_name.present?
    if sent_from.present?
      "User #{sent_from_id}"
    else
      format_phone_number
    end
  end

  def format_phone_number
    "+1 (#{phone_number[0..2]}) #{phone_number[3..5]}-#{phone_number[6..9]}"
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
      slack_message += "#{format_phone_number} has opted out of text messages from PKUT.\nThey will no longer receive text messages from us (Including messages sent from the admin text messaging page).\nIn order to re-enable messages, they must send a text message saying \"START\" to us, and then log in to their account, Home, then click Notifications, then the button that says 'Text Me!'\nIf the message sends successfully, they will be able to receive text messages from us again.\n"
    else
      escaped_body = body.split("\n").map { |line| "\n>#{line}" }.join("")
      slack_message += "*Received text message from: #{format_phone_number}*\n#{escaped_body}"
      respond_link = Rails.application.routes.url_helpers.messages_url(phone_number: phone_number)
      slack_message += "\n<#{respond_link}|Click here to respond!>"
    end
    slack_message += sent_from.present? ? "\nPhone Number seems to match: <#{user_link}|#{sent_from.id} - #{sent_from.email}>" : ""
    channel = Rails.env.production? ? "#support" : "#slack-testing"
    SlackNotifier.notify(slack_message, channel)
  end

  def phone_number
    self.stripped_phone_number
  end
  def phone_number=(new_phone)
    self.stripped_phone_number = new_phone
  end

  private

  def assign_users
    if sent_from.nil?
      current_user ||= nil
      self.sent_from_id = current_user.try(:id)
    end
    if sent_to.nil?
      user = lookup_receiver_by_phone_number
      self.sent_to_id = user.try(:id)
    end
  end

  def strip_phone_number(number); self.class.strip_phone_number(number); end
  def self.strip_phone_number(number)
    return 'No Number Found' unless number.present?
    number.gsub(/[^\d]/, "")
  end

  def remove_non_digits_from_db_phone_number
    self.stripped_phone_number = strip_phone_number(stripped_phone_number).gsub(/[^\d]/, "")
  end

  def phone_number_length
    unless stripped_phone_number.length >= 10
      errors.add(:phone_number, "must contain at least 10 digits.")
    end
  end

  def try_to_notify_slack_of_unread_message
    unless sent_from.try(:instructor?)
      NotifySlackOfUnreadMessageWorker.perform_in(2.seconds, self.id)
    end
  end

end
