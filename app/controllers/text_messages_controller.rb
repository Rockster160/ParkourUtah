class TextMessagesController < ApplicationController
  before_action :validate_admin

  def show
    @phone_number = params[:id]
    @new_message = current_user.text_messages.new
    @text_messages = TextMessage.where(stripped_phone_number: @phone_number).order(created_at: :asc)
    @number_user = @text_messages.first.try(:user)
  end

  def create
    @text_message = current_user.text_messages_sent.create(text_message_params.merge(sent_to_user: true))
    @number_user = @text_message.user

    if @text_message.persisted?
      @text_message.deliver
      redirect_to text_message_path(@text_message.phone_number), notice: "Successfully sent!"
    else
      redirect_to text_message_path(@text_message.phone_number, body: @text_message.body), alert: "Failed to send"
    end
  end

  private

  def text_message_params
    params.require(:text_message).permit(:stripped_phone_number, :body)
  end

end
