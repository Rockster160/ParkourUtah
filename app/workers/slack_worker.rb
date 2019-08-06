require 'slack-notifier'
class SlackWorker
  include Sidekiq::Worker
  WEBHOOK_URL = ENV["PKUT_SLACK_HOOK"]

  # https://api.slack.com/docs/attachments

  def perform(message, channel = '#slack-testing', username = 'PKUT-Bot', icon_emoji = ':pkut:', attachments=[])
    ::Slack::Notifier.new(WEBHOOK_URL, channel: channel, username: username, icon_emoji: icon_emoji, attachments: attachments).ping(message)
  end

end
