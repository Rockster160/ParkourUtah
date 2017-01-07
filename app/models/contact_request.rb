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

class ContactRequest < ActiveRecord::Base

  def notify_slack
    email_url = Rails.application.routes.url_helpers.batch_email_admin_url(recipients: email)
    text_url = Rails.application.routes.url_helpers.batch_text_message_admin_url(recipients: phone.gsub(/[^0-9]/, ''))
    escaped_body = body.split("\n").map { |line| "\n>#{line}" }.join("")
    contact_message = "*#{name}* has requested Contact!\n#{escaped_body}\nReach out by contacting: <#{email_url}|Via Email> or <#{text_url}|Via Text>\nOr call: #{phone}"
    channel = Rails.env.production? ? "#support" : "#slack-testing"
    SlackNotifier.notify(contact_message, channel)
  end

end
