class MessagesController < ApplicationController
  before_action :validate_admin

  def mark_messages_as_read
    Message.unread.where(id: params[:ids]).each(&:read!)
    head :ok
  end

  def index
    if params[:phone_number].present?
      @phone_number = params[:phone_number].to_s.gsub(/[^0-9]/, "").last(10)
      @number_user = User.by_phone_number(@phone_number).first
    end

    @text_messages = Message.none
    return unless request.xhr?

    @text_messages = Message.by_phone_number(@phone_number).order(created_at: :asc)

    if params[:last_sync].present?
      @text_messages = @text_messages.where("created_at > ?", Time.at(params[:last_sync].to_i))
    end

    @text_messages.each(&:read!)
    render template: 'messages/messages', layout: false
  end

  def create
    @text_message = current_user.sent_messages.create(message_params.merge(message_type: Message.message_types[:text]))
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
