class MessagesController < ApplicationController
  before_action :validate_instructor

  def mark_messages_as_read
    Message.unread.where(id: params[:ids]).each(&:read!)
    head :ok
  end

  def index
    @chat_room = ChatRoom.find(params[:chat_room_id])
    @text_messages = Message.by_phone_number(@phone_number).order(created_at: :asc)

    if params[:last_sync].present?
      @text_messages = @text_messages.where("created_at > ?", Time.at(params[:last_sync].to_i))
    end

    @text_messages.each(&:read!)
    render template: 'messages/messages', layout: false
  end

  def create
    @text_message = current_user.sent_messages.chat.create(message_params)
    @number_user = @text_message.try(:sent_to)
    @text_message.deliver if @text_message.persisted?

    if request.xhr?
      head :created
    else
      redirect_to messages_path(phone_number: @text_message.phone_number), notice: "Successfully sent!"
    end
  end

  private

  def message_params
    params.require(:message).permit(:phone_number, :body)
  end

end
