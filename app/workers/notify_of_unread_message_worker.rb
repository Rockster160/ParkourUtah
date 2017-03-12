class NotifyOfUnreadMessageWorker
  include Sidekiq::Worker

  def perform(message_id)
    message = Message.find(message_id)

    return unless message.present? && message.persisted? && message.unread?

    if message.text? && !message.sent_from.try(:instructor?) && sent_from_id != 0
      message.notify_slack
    elsif message.chat?
      chat_room_link = Rails.application.routes.url_helpers.chat_room_url(message.chat_room)

      users_to_notify = message.chat_room.chat_room_users.where(has_unread_messages: true).map(&:user) - [message.sent_from]

      users_to_notify.each do |user_to_notify|
        SmsMailerWorker.perform_async(user_to_notify.phone_number, "You've received a message from ParkourUtah!\n#{chat_room_link}")
      end
    end

  end

end
