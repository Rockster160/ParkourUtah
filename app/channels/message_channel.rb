class MessageChannel < ApplicationCable::Channel

  def subscribed
    stream_from "#{params['channel_id']}_channel"
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end

  def send_message(data)
    chat_room_id = data['chat_room_id']
    chat_room = ChatRoom.find(chat_room_id)

    message = chat_room.messages.create!(body: data['message'], sent_from: current_user)
    message.deliver if chat_room.text?
  end

  def user_is_typing(data)
    user_id = data['user_id']
    user = User.find(user_id)

    chat_room_id = data['chat_room_id']
    chat_room = ChatRoom.find(chat_room_id)

    ActionCable.server.broadcast "room_#{chat_room_id}_channel", is_typing: user.display_name, typing_user_id: user_id
  end

end
