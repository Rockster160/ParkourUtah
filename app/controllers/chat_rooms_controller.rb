class ChatRoomsController < ApplicationController
  include ApplicationHelper
  before_action :validate_user_signed_in
  before_action :verify_user_has_permission_to_view_room, only: [ :show ]

  def index
    @chat_rooms = ChatRoom.joins(:messages).distinct.viewable_by_user(current_user).order(updated_at: :desc).page(params[:page])
  end

  def by_phone_number
    redirect_to ChatRoom.text.find_or_create_by(name: strip_phone_number(params[:phone_number]))
  end

  def show
    @messages = chat_room.messages.order(created_at: :desc)
  end

  private

  def chat_room
    @chat_room ||= ChatRoom.find(params[:id])
  end

  def verify_user_has_permission_to_view_room
    # if user.chat_room_users.any? {|ru|ru.chat_room_id == params[:id]} || user.has_permission_to_view_chat_room?(room)
  end

end
