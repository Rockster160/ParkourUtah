class ChatRoomsController < ApplicationController
  include ApplicationHelper
  before_action :validate_user_signed_in
  before_action :verify_user_has_permission_to_view_room, only: [ :show ]

  def index
    @chat_rooms = current_user.chat_rooms.by_most_recent(:last_message_received_at).page(params[:page])
  end

  def by_phone_number
    redirect_to ChatRoom.text.find_or_create_by(name: strip_phone_number(params[:phone_number]))
  end

  def show
    @messages = chat_room.messages.by_most_recent(:created_at)
  end

  private

  def chat_room
    @chat_room ||= ChatRoom.find(params[:id])
  end

  def verify_user_has_permission_to_view_room
    # if user.chat_room_users.any? {|ru|ru.chat_room_id == params[:id]} || user.has_permission_to_view_chat_room?(room)
  end

end
