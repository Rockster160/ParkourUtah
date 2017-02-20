class ChatChannel < ApplicationCable::Channel
  def subscribed
    stream_from "#{params['chat_room_id']}_channel"
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end

  def send_message(data)
    # Mark these as text messages
    message = current_user.sent_messages.text.create!(body: data['message'], phone_number: data['chat_room_id'][6..-1])
    message.deliver
  end
end
