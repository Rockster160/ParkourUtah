class PeepsController < ApplicationController
  include EmailHelper
  before_action :still_signed_in, :validate_instructor

  EmailBody = Struct.new(:subject, :body, :recipients, :email_type)

  def email_body
    @email = EmailBody.new(*decoded_email_params)

    raw_html = html(@email.body)

    email_source = ApplicationMailer.email('', @email.subject || '', raw_html || '').body.raw_source

    respond_to do |format|
      if valid_html?(raw_html)
        format.json { render json: {email_body: email_source} }
      else
        format.json { render nothing: true, status: 422 }
      end
    end
  end

  def admin_texter
    @users = User.where(id: params[:user_ids])
  end

  def send_batch_texts
    phone_numbers = params[:recipients].gsub(/[^\d|,]/, '').split(",").map(&:squish)
    @success = []
    @failed = []
    phone_numbers.each do |phone_number|
      if phone_number.length == 10
        SmsMailerWorker.perform_async(phone_number, params[:message])
        @success << phone_number
      else
        @failed << phone_number
      end
    end
    render :admin_texter
  end

  def batch_emailer
    @email = EmailBody.new(*decoded_email_params)
  end

  def send_batch_emailer
    @email = EmailBody.new(*decoded_email_params)
    raw_html = html(@email.body)
    BatchEmailerWorker.perform_async(@email.subject, raw_html, @email.recipients, @email.email_type)
    redirect_to dashboard_path, notice: 'Sweet! I will send that out to them!'
  end

  def cheat_login
    user = User.find_by_encrypted_password(Base64.urlsafe_decode64(params[:ecp]))
    sign_out :user
    sign_in user
    redirect_to edit_user_registration_path
  end

  def destroy_user
    if params[:confirmation] == "DELETE"
      User.find(params[:id]).destroy
      redirect_to recent_users_path, notice: "User successfully deleted."
    else
      redirect_to recent_users_path, notice: "Sorry, DELETE was not entered correctly. User still exists."
    end
  end

  private

  def decoded_email_params
    if params[:encoded] == 'true'
      [Base64.urlsafe_decode64(params[:subject] || ''), Base64.urlsafe_decode64(params[:body] || ''), Base64.urlsafe_decode64(params[:recipients] || ''), Base64.urlsafe_decode64(params[:email_type] || '')]
    else
      [params[:subject], params[:body], params[:recipients], params[:email_type]]
    end
  end

end
