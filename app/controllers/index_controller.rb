require 'net/http'
class IndexController < ApplicationController
  before_action :still_signed_in
  skip_before_action :verify_authenticity_token

  def venmo
    # https://api.venmo.com/v1/oauth/authorize?client_id=3191&scope=make_payments&response_type=code
    response = Net::HTTP.post_form(URI.parse("https://api.venmo.com/v1/oauth/access_token"),
      {
        client_id: ENV["PKUT_VENMO_ID"],
        code: params[:code],
        client_secret: ENV["PKUT_VENMO_SECRET"]
      }
    )
    unless response.body["error"].present?
      expires_at = DateTime.now + response.body["expires_in"].to_i.seconds
      Venmo.first.update(
        access_token: response.body["access_token"],
        refresh_token: response.body["refresh_token"],
        expires_at: expires_at
      )
    end
    SmsMailerWorker.perform_async('3852599640', params[:code])
    SmsMailerWorker.perform_async('3852599640', "#{response.body}")
    redirect_to root_path, notice: "Thanks! We've got that updated."
  end

  def get_request
    render json: Automator.open?
  end

  def give_request
    if params[:secret] == "Rocco"
      if params[:open] == "true"
        Automator.activate!
      else
        Automator.deactivate!
      end
    end
    respond_to do |format|
      format.json { head :no_content }
    end
  end

  def sms_receivable
    current_user.notifications.update(sms_receivable: true)
    SmsMailerWorker.perform_async(current_user.phone_number, 'Thank you! You will once again be able to receive text message notifications from ParkourUtah.')
  end

  def page_not_found
    @protocol = "404"
  end

  def page_broken
    @protocol = "500"
  end

  def index
    @instructors = User.where("role > ?", 0).sort_by { |u| u.instructor_position }

    all_events = Event.where("date > ?", Date.today)
    @events = all_events.group_by { |event| [event.date.month, event.date.day] }
    @cities = all_events.group_by { |event| event.city }.keys.sort
    @classes = all_events.group_by { |event| event.class_name }.keys
  end

  def update_notifications
    current_user.notifications.blow!
    params[:notify].each do |attribute, value|
      current_user.notifications.update(attribute => true)
    end
    redirect_to edit_user_registration_path
  end

  def receive_sms
    is_me = params["From"] == "+13852599640"
    unless is_me
      ::SmsMailerWorker.perform_async('3852599640', "From: #{params["From"]}\nMessage: #{params["Body"]}")
    end

    if params["Body"].split('').length < 10 && params["Body"].downcase[0..3] != 'pass'
      if ["Open.", "Close."].include?(params["Body"].split.join)
        Automator.activate!
      else
      end
    else
      unless is_me
        num = params["From"].split('').map {|x| x[/\d+/]}.join
        ::SmsMailerWorker.perform_async(num, "This is an automated text messaging system. \nIf you have questions about class, please contact the Instructor. Their contact information is available in the class details. \nIf you would like to stop receiving Notifications, please disable text notifications in your Account Settings on parkourutah.com/account#notifications")
      end
    end

    if is_me
      if params["Body"] == 'pass'
        contact_request = ContactRequest.select { |cr| cr.success == false }.sort_by(&:created_at).last
        if contact_request
          pass = {}
          pass["name"] = contact_request.name
          pass["email"] = contact_request.email
          pass["phone"] = contact_request.phone
          pass["comment"] = contact_request.body
          ::ContactMailerWorker.perform_async(pass)
          contact_request.update(success: true)
          ::SmsMailerWorker.perform_async('3852599640', "Allowed contact request from: #{contact_request.name}.")
        else
          ::SmsMailerWorker.perform_async('3852599640', "No previous request")
        end
      elsif params["Body"].downcase =~ /talk/
        ::SmsMailerWorker.perform_async('3852599640', RoccoLogger.by_date.logs)
      elsif params["Body"].downcase =~ /pass/
        name = params["Body"].gsub('pass ', '')
        contact_request = ContactRequest.select { |cr| cr.success == false && cr.name == name }.last
        if contact_request
          pass = {}
          pass["name"] = contact_request.name
          pass["email"] = contact_request.email
          pass["phone"] = contact_request.phone
          pass["comment"] = contact_request.body
          ::ContactMailerWorker.perform_async(pass)
          contact_request.update(success: true)
          ::SmsMailerWorker.perform_async('3852599640', "Allowed contact request from: #{contact_request.name}.")
        else
          ::SmsMailerWorker.perform_async('3852599640', "No such request")
        end
      end
    end
    head :ok
  end

  def update
    update_address
    update_phone
    redirect_to edit_user_registration_path
  end

  def coming_soon
  end

  def contact
    success = false
    if /\(\d{3}\) \d{3}-\d{4}/ =~ params[:phone]
      flash[:notice] = "Thanks! We'll have somebody get in contact with you shortly."
      ::ContactMailerWorker.perform_async(params)
      success = true
    end
    contact_request = ContactRequest.create(
      user_agent: request.env['HTTP_USER_AGENT'],
      phone: params[:phone],
      name: params[:name],
      email: params[:email],
      body: params[:comment],
      success: success
    )
    if params[:phone].split('').map {|x| x[/\d+/]}.join.length >= 7 && !contact_request.success
      ::SmsMailerWorker.perform_async('3852599640', "#{contact_request.success ? '' : "FAILED\n"}UserAgent: #{contact_request.user_agent}\n#{contact_request.phone} requested help.\nSuccess: #{contact_request.success}\nJS Enabled: #{params[:enabled]}\n#{contact_request.name}\n#{contact_request.email}\n#{contact_request.body}")
    end
    redirect_to root_path
  end

  def contact_page
  end

  def unsubscribe
    if current_user == User.find(params[:id]) && User.find(params[:id]).notifications.update(params[:type] => false)
      flash[:notice] = "You have been successully unsubscribed."
    else
      flash[:alert] = "You must be signed in to unsubscribe."
    end
    redirect_to root_path
  end

  private

  def update_phone
    if params[:phone_number]
      current_user.phone_number = params[:phone_number]
      if current_user.save
        flash[:notice] = "Your phone number has been successfully updated!"
      else
        flash[:alert] = current_user.errors.full_messages.first
      end
    end
  end

  def update_address
    current_user.address ||= Address.new
    if params[:address]
      current_user.address.update(params[:address].permit(:line1, :line2, :city, :state, :zip))
      if current_user.address.is_valid?
        flash[:notice] = "Your address has been successfully updated!"
      else
        flash[:alert] = "There was an error saving your address."
      end
    end
  end

  def still_signed_in
    current_user.still_signed_in! if current_user
  end

end
