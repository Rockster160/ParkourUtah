class MessagesController < ApplicationController
  before_action :set_chat_room

  def mark_messages_as_read
    Message.where(id: params[:ids]).each(&:read!)
    current_user.chat_room_users.where(has_unread_messages: true, chat_room_id: params[:chat_room_id]).update_all(has_unread_messages: false)
    head :ok
  end

  def index
    @messages = @chat_room.messages.order(created_at: :asc)

    if params[:last_sync].present?
      @messages = @messages.where("created_at > ?", Time.at(params[:last_sync].to_i))
    end

    @messages.where.not(sent_from_id: current_user.id).each(&:read!)
    render template: 'messages/index', layout: false
  end

  def create
    message = @chat_room.messages.create!(body: data['message'], sent_from: current_user)
    message.deliver if message.persisted?

    if request.xhr?
      head :created
    else
      redirect_to chat_room_path(@chat_room), notice: "Successfully sent!"
    end
  end

  private

  def set_chat_room
    @chat_room = ChatRoom.find(params[:chat_room_id]) if params[:chat_room_id].present?
  end

  def message_params
    params.require(:message).permit(:chat_room_id, :body)
  end

end
