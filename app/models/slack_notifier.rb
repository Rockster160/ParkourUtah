class SlackNotifier

  def self.notify(message, channel = '#slack-testing', username = 'PKUT', icon_emoji = ':pkut:', attachments = [])
    ::SlackWorker.perform_async(message, channel, username, icon_emoji, attachments)
  end

end
