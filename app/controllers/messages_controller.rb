class MessagesController < ApplicationController
  before_action :validate_admin

  def show
    @phone_number = params[:id]
    @new_message = current_user.sent_messages.new
    # Read Messages?
    @text_messages = Message.by_phone_number(@phone_number).order(created_at: :asc)
    @number_user = @text_messages.first.try(:user)
  end

  def create
    @text_message = current_user.sent_messages.create(message_params.merge(message_type: Message.message_types[:text]))
    @number_user = @text_message.try(:sent_to)

    if @text_message.persisted?
      @text_message.deliver
      redirect_to message_path(@text_message.phone_number), notice: "Successfully sent!"
    else
      redirect_to message_path(@text_message.phone_number, body: @text_message.body), alert: "Failed to send"
    end
  end

  private

  def message_params
    params.require(:message).permit(:phone_number, :body)
  end

end
