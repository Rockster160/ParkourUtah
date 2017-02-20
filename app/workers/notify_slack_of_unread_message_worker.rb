class NotifySlackOfUnreadMessageWorker
  include Sidekiq::Worker

  def perform(message_id)
    message = Message.find(message_id)

    if message.present? && message.try(:unread?)
      message.notify_slack
    end
  end

end
