class ChatRoomsController < ApplicationController
  before_action :validate_user_signed_in
  before_action :verify_user_has_permission_to_view_room, only: [ :show ]

  def index
    @chat_rooms = ChatRoom.viewable_by_user(current_user).order(updated_at: :desc).page(params[:page])
  end

  def show
  end

  # def mark_messages_as_read
  # end

  private

  def chat_room
    @chat_room ||= ChatRoom.find(params[:id])
  end

  def verify_user_has_permission_to_view_room
    # if user.chat_room_users.any? {|ru|ru.chat_room_id == params[:id]} || user.has_permission_to_view_chat_room?(room)
  end

end
