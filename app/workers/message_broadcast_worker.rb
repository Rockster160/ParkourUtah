class MessageBroadcastWorker
  include Sidekiq::Worker

  def perform(message_id)
    message = Message.find(message_id)

    ActionCable.server.broadcast "phone_#{message.phone_number}_channel", message: render_message(message)
  end

  private

  def render_message(message)
    MessagesController.render template: 'messages/messages', locals: { messages: [message] }, layout: false
  end

end
