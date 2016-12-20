require 'net/http'
class IndexController < ApplicationController
  before_action :still_signed_in
  skip_before_action :verify_authenticity_token

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
    @instructors = User.instructors

    future_events = EventSchedule.in_the_future
    @cities = future_events.pluck(:city).uniq.sort
  end

  def update_notifications
    current_user.notifications.blow!
    params[:notify].each do |attribute, value|
      current_user.notifications.update(attribute => true)
    end
    redirect_to edit_user_registration_path
  end

  def receive_sms
    raw_number = params["From"].gsub(/[^0-9]/, "").last(10)
    user = User.where("phone_number ILIKE ?", "%#{raw_number}%").first
    if %w(STOP STOPALL UNSUBSCRIBE CANCEL END QUIT).include?(params["Body"].squish.upcase)
      user.notifications.update(sms_receivable: false) if user.present? && user.notifications.present?
      default_message = "#{params["From"]} has opted out of text messages from PKUT.\nThey will no longer receive text messages from us (Including messages sent from the admin text messaging page).\nIn order to re-enable messages, they must send a text message saying \"START\" to us, and then log in to their account, Home, then click Notifications, then the button that says 'Text Me!'\nIf the message sends successfully, they will be able to receive text messages from us again."
      user_message = user.present? ? "\nPhone Number seems to match: <#{admin_user_url(user, host: 'http://parkourutah.com')}|#{user.id} - #{user.email}>" : ""
      slack_message = default_message + user_message
    else
      escaped_body = params["Body"].split("\n").map { |line| "\n>#{line}" }.join("")
      default_message = "*Received text message from: #{params["From"]}*\n>#{escaped_body}"
      user_message = user.present? ? "\nPhone Number seems to match: <#{admin_user_url(user)}|#{user.id} - #{user.email}>" : ""
      respond_message = "\n<#{batch_text_message_admin_url(recipients: raw_number, host: 'http://parkourutah.com')}|Click here to respond!>"
      slack_message = default_message + user_message + respond_message
    end
    SlackNotifier.notify(slack_message, "#support")
    head :ok
  end

  def update
    update_address
    update_phone
    redirect_to edit_user_registration_path
  end

  def contact
    success = false
    if /\(\d{3}\) \d{3}-\d{4}/ =~ params[:phone]
      flash[:notice] = "Thanks! We'll have somebody get in contact with you shortly."
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
    if params[:phone].split('').map {|x| x[/\d+/]}.join.length >= 7 || success
      contact_request.notify_slack
    end
    redirect_to root_path
  end

  def contact_page
  end

  def unsubscribe
    if User.find(params[:id]).notifications.update(params[:type] => false)
      flash[:notice] = "You have been successully unsubscribed."
    else
      flash[:alert] = "Failed to unsubscribe."
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

end
