class MessagesController < ApplicationController
  before_action :validate_instructor
  before_action :set_chat_room

  def mark_messages_as_read
    Message.unread.where(id: params[:ids]).each(&:read!)
    head :ok
  end

  def index
    @messages = @chat_room.messages.order(created_at: :asc)

    if params[:last_sync].present?
      @messages = @messages.where("created_at > ?", Time.at(params[:last_sync].to_i))
    end

    @messages.each(&:read!)
    render template: 'messages/index', layout: false
  end

  def create
    binding.pry
    # @text_message = current_user.sent_messages.chat.create(message_params)
    # @number_user = @text_message.try(:sent_to)
    # @text_message.deliver if @text_message.persisted?
    #
    # if request.xhr?
    #   head :created
    # else
    #   redirect_to messages_path(phone_number: @text_message.phone_number), notice: "Successfully sent!"
    # end
  end

  private

  def set_chat_room
    @chat_room = ChatRoom.find(params[:chat_room_id])
  end

  def message_params
    params.require(:message).permit(:chat_room_id, :body)
  end

end
