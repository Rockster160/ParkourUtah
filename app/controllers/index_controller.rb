class IndexController < ApplicationController
  before_action :still_signed_in
  skip_before_action :verify_authenticity_token

  def get_request
    render json: Automator.open?
  end

  def give_request
    if params[:secret] == "Rocco"
      Automator.deactivate!
    end
  end

  def page_not_found
    @protocol = "404"
  end

  def page_broken
    @protocol = "500"
  end

  def index
    @date = params[:date] ? Date.parse(params[:date]) : Date.today

    @instructors = User.where("role > ?", 0).sort_by { |u| u.instructor_position }

    all_events = Event.where(nil)
    @events = all_events.group_by { |event| [event.date.month, event.date.day] }
    @cities = all_events.group_by { |event| event.city }.keys.sort
    @classes = all_events.group_by { |event| event.class_name }.keys

    @selected_cities = params[:cities] ? params[:cities] : @cities
    @selected_classes = params[:classes] ? params[:classes] : @classes
  end


  def update_notifications
    current_user.notifications.blow!
    params[:notify].each do |attribute, value|
      current_user.notifications.update(attribute => true)
    end
    redirect_to edit_user_registration_path
  end

  def receive_sms
    api = Twilio::REST::Client.new(ENV['PKUT_TWILIO_ACCOUNT_SID'], ENV['PKUT_TWILIO_AUTH_TOKEN'])
    api.account.messages.create(
      body: "From: #{params["From"]}\nMessage: #{params["Body"]}",
      to: "+3852599640",
      from: "+17405714304"
    )
    # number = params["From"]
    # if params["Body"].downcase.split.join == "stop"
    #   User.find_by_phone_number(number).subscriptions.each do |subscription|
    #     subscription.destroy
    #   end
    #   ::SmsMailerWorker.perform_async(number, "You have been unsubscribed from all messages from ParkourUtah.")
    #   # TODO Send email?
    # end
  end

  def update
    update_address
    update_phone
    redirect_to edit_user_registration_path
  end

  def coming_soon
  end

  def contact
    flash[:notice] = "Thanks! We'll have somebody get in contact with you shortly."
    ::ContactMailerWorker.perform_async(params)
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
