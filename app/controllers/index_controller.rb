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
    @instructors = User.instructors.where(should_display_on_front_page: true)

    future_events = EventSchedule.in_the_future
    @cities = future_events.pluck(:city).uniq.sort
  end

  def update_notifications
    current_user.notifications.blow!
    params[:notify].each do |attribute, value|
      current_user.notifications.update(attribute => true)
    end
    redirect_to edit_user_path
  end

  def receive_sms
    raw_number = params["From"].gsub(/[^0-9]/, "").last(10)
    Message.create(stripped_phone_number: raw_number, body: params["Body"])
    head :ok
  end

  def update
    update_address
    update_phone
    redirect_to edit_user_path
  end

  def contact
    success = false
    if /\(\d{3}\) \d{3}-\d{4}/ =~ params[:phone] && blacklisted_body?
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
    phone_digits = params[:phone].split('').map {|x| x[/\d+/]}.join
    if !blacklisted_body? && ((phone_digits.length >= 7 && phone_digits.length <= 10) || success)
      contact_request.notify_slack
    end
    redirect_to root_path
  end

  def contact_page
  end

  def unsubscribe
    if params[:type].present? &&  params[:id].present?
      unsubscribe_type = params[:type]
      user_id = params[:id]
    else
      unsubscribe_params = Rack::Utils.parse_nested_query(Base64.urlsafe_decode64(params[:unsubscribe_code] || ''))
      unsubscribe_type = unsubscribe_params['unsubscribe'].try(:to_sym) || :all
      user_id = unsubscribe_params['user_id'].try(:to_i)
    end

    if User.find(user_id).unsubscribe_from(unsubscribe_type)
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

  def blacklisted_body?
    @blacklisted ||= begin
      body_blacklist.any? { |blacklist_string| params[:comment].include?(blacklist_string) }
    end
  end

  def body_blacklist
    [
      "business for At Least 1 year",
      "Cheap Coach",
      "Our Tiffany Jewellery Store",
      "Swiss Replica Watch",
      "Cheap Moncler jackets",
      "revolution in online promotion",
      "buy cs6 photoshop cheapest",
      "omasex.online",
      "deposito e investimento",
      "mp3dj.eu",
      "buy essay for college",
      "I love reading phorums posted here",
      "You have a product, service and have no customers?",
      "buy a cheap",
      "href=",
      "GetBusinessFunded"
    ]
  end

end
