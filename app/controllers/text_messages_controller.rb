class TextMessagesController < ApplicationController
  before_action :validate_admin

  def show
    @new_message = current_user.text_messages.new
    @text_messages = TextMessage.where(stripped_phone_number: params[:id])
    @user = @text_messages.first.try(:user)
  end

  def create
    @text_message = current_user.text_messages_sent.create(text_message_params)

    if @text_message.persisted?
      @text_message.deliver
      redirect_to text_message_path(@user.phone_number), notice: "Successfully sent!"
    else
      render :new
    end
  end

  private

  def text_message_params
    params.require(:text_message).permit()
  end

end
