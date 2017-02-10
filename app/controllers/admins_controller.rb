class AdminsController < ApplicationController
  include EmailHelper
  before_action :still_signed_in
  before_action :validate_admin, except: [ :dashboard ]
  before_action :validate_instructor, only: [ :dashboard ]

  EmailBody = Struct.new(:subject, :body, :recipients, :email_type)

  def dashboard
    @classes = EventSchedule.events_today
  end

  def purchase_history
    @line_item_ids = (params[:line_item_ids].try(:compact) || []).map(&:to_i)
    line_items = LineItem.where(id: @line_item_ids)
    @items_with_users = line_items.map do |line_item|
      {
        line_item_id: line_item.id,
        users: line_item.users_who_purchased
      }
    end
  end

  def summary
    if params[:start_date]
      start_date = Time.zone.parse(params[:start_date]) rescue nil
    end
    if params[:end_date]
      end_date = Time.zone.parse(params[:end_date]) rescue nil
    end
    start_date ||= Time.zone.now

    if start_date.present? && end_date.present?
      @summary = ClassSummaryCalculator.new(start_date: start_date, end_date: end_date).generate
    else
      @summary = nil
    end
  end

  def batch_text_message
    @users = User.where(id: params[:user_ids])
    case params[:template]
    when "default-response"
      params[:message] = "This is an automated text messaging system. \nIf you have questions about class, please contact the Instructor. Their contact information is available in the class details. \nIf you would like to stop receiving Notifications, please disable text notifications in your Account Settings on parkourutah.com/account#notifications"
    end
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
    render :batch_text_message
  end

  def batch_email
    @email = EmailBody.new(*decoded_email_params)
  end

  def send_batch_emailer
    @email = EmailBody.new(*decoded_email_params)
    raw_html = html(@email.body)
    BatchEmailerWorker.perform_async(@email.subject, raw_html, @email.recipients, @email.email_type)
    redirect_to dashboard_path, notice: 'Sweet! I will send that out to them!'
  end

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

  private

  def decoded_email_params
    if params[:encoded] == 'true'
      [Base64.urlsafe_decode64(params[:subject] || ''), Base64.urlsafe_decode64(params[:body] || ''), Base64.urlsafe_decode64(params[:recipients] || ''), Base64.urlsafe_decode64(params[:email_type] || '')]
    else
      [params[:subject], params[:body], params[:recipients], params[:email_type]]
    end
  end

end
