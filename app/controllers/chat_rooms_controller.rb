class ChatRoomsController < ApplicationController
  include ApplicationHelper
  before_action :validate_user_signed_in
  before_action :verify_user_has_permission_to_view_room, only: [ :show ]

  def index
    @chat_rooms = current_user.chat_rooms.by_most_recent(:last_message_received_at)
    @chat_rooms = @chat_rooms.chat unless current_user.admin?
    @chat_rooms = @chat_rooms.page(params[:page])
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
    unless chat_room.viewable_by_user?(current_user)
      redirect_to chat_rooms_path
    end
  end

end
