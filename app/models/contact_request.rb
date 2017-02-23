# == Schema Information
#
# Table name: contact_requests
#
#  id         :integer          not null, primary key
#  user_agent :string
#  phone      :string
#  name       :string
#  email      :string
#  body       :string
#  success    :boolean
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class ContactRequest < ApplicationRecord

  scope :by_fuzzy_text, ->(fuzzy_text) {
    formatted_text = fuzzy_text.to_s.downcase
    text = "%#{formatted_text}%"
    phone_column = "REGEXP_REPLACE(phone, '[^\\w]', '', 'g') ILIKE ?"
    where("#{phone_column} OR LOWER(name) ILIKE ? OR LOWER(email) ILIKE ? OR LOWER(body) ILIKE ?", text, text, text, text)
  }

  def log_message
    current_user ||= nil
    Message.text.create(chat_room_name: phone, body: "Request For Contact: #{body}", sent_from: current_user, created_at: created_at, do_not_deliver: true)
  end

  def notify_slack
    email_url = Rails.application.routes.url_helpers.batch_email_admin_url(recipients: email)
    text_url = Rails.application.routes.url_helpers.messages_url(phone_number: phone.gsub(/[^0-9]/, ''))
    escaped_body = body.split("\n").map { |line| "\n>#{line}" }.join("")
    contact_message = "*#{name}* has requested Contact!\n#{escaped_body}\nReach out by contacting: <#{email_url}|Via Email> or <#{text_url}|Via Text>\nOr call: #{phone}"
    channel = Rails.env.production? ? "#support" : "#slack-testing"
    SlackNotifier.notify(contact_message, channel)
  end

end
