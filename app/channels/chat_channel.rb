class ChatChannel < ApplicationCable::Channel
  def subscribed
    stream_from "#{params['chat_room_id']}_channel"
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end

  def send_message(data)
    chat_room_id = data['chat_room_id'][5..-1]
    chat_room = ChatRoom.find(chat_room_id)

    message = chat_room.messages.create!(body: data['message'], sent_from: current_user)
    message.deliver if chat_room.text?
  end
end
