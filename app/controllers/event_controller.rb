class EventController < ApplicationController
  before_action :validate_user, only: [ :create, :new ]

  def index
    @events = Event.sort_by_token
  end

  def show
    @event = Event.find(params[:id])
  end

  def detail
    @event = Event.find(params[:id])
    respond_to do |format|
      format.html { render layout: !request.xhr? }
    end
  end

  def cancel
    if params[:should_happen] == "true"
      Event.find(params[:id]).uncancel!
      flash[:notice] = "Event has successfully been uncancelled."
    else
      Event.find(params[:id]).cancel!
      flash[:notice] = "Event has successfully been cancelled."
    end
    redirect_to :back
  end

  def send_message_to_subscribers
    event = Event.find(params[:id])
    users = event.subscribed_users
    users.each do |user|
      if user.notifications.text_class_cancelled? && user.notifications.sms_receivable?
        ::SmsMailerWorker.perform_async(user.phone_number, params[:message])
      end
    end
    redirect_to :back, notice: 'Your message has been sent.'
  end

  def new
    @event = Event.new
    all_events = Event.all.to_a
    @cities = all_events.group_by { |event| event.city }.keys.sort
    @classes = all_events.group_by { |event| event.class_name }.keys.sort
    @instructors = User.where("role > ?", 0)
  end

  def cities
    @cities = Event.cities
  end

  def city
    @city = params[:city]
    @events = Event.sort_by_token.select { |e| e.city == @city }
  end

  def color_class
    Event.set_class_color(params[:class_name], params[:color])
    redirect_to edit_colors_path
  end

  def color_classes
    @classes = Event.all.group_by { |e| e.class_name }.keys
  end

  def create
    date_time = convertToRailsTime(params[:date], params[:time])
    dates = []
    iterate = params[:repeat] ? 50 : 1
    iterate.times do |each_week|
      dates << date_time + (each_week.weeks)
    end
    params[:event][:token] = Time.now.to_i
    dates.each do |date|
      params[:event][:date] = date
      Event.create(event_params)
    end
    redirect_to calendar_show_path("all")
  end

  def edit
    @event = Event.find(params[:id])
  end

  def update
    event = Event.find(params[:id])
    hour = params[:time][:meridiam] == "AM" ? params[:time][:hour].to_i : params[:time][:hour].to_i + 12
    min = params[:time][:minute].to_i
    token = event.token
    if params[:all]
      Event.where(token: token).each do |events|
        params[:event][:date] = events.date.change({hour: hour, min: min})
        events.update(event_params)
        if events.spot_events.first
          events.spot_events.first.update(spot_id: params[:spot_id]) if params[:spot_id]
        else
          events.spot_events.create(spot_id: params[:spot_id]) if params[:spot_id]
        end
      end
    else
      params[:event][:date] = event.date.change({hour: hour, min: min})
      event.update(event_params)
      if event.spot_events.first
        event.spot_events.first.update(spot_id: params[:spot_id]) if params[:spot_id]
      else
        event.spot_events.create(spot_id: params[:spot_id]) if params[:spot_id]
      end
    end
    redirect_to :back
  end

  def destroy
    if params[:future]
      event = Event.find(params[:id])
      token = event.token
      date = event.date
      Event.where("token = :token AND date >= :date", token: token, date: date).each(&:destroy)
    else
      Event.find(params[:id]).destroy
    end
    redirect_to calendar_show_path("all")
  end

  def subscribe
    if current_user.phone_number_is_valid?
      event = Event.find(params[:id])
      current_user.subscriptions.create(event_id: event.id, token: event.token)
      redirect_to :back, notice: "You have successfully subscribed to this event."
    else
      redirect_to edit_user_registration_path, alert: "You must have an associated phone number to subscribe to events."
    end
  end

  def unsubscribe
    if Subscription.where(user_id: current_user.id, event_id: params[:id]).first.destroy
      redirect_to :back, notice: "You have successfully unsubscribed from this event."
    else
      redirect_to :back, alert: "There was an error. Try again later."
    end
  end

  private

  def convertToRailsTime(date, time)
    new_date = date.split("/")

    year = new_date[2].to_i
    month = new_date[0].to_i
    day = new_date[1].to_i
    hour = time[:meridiam] == "AM" ? time[:hour].to_i : time[:hour].to_i + 12
    min = time[:minute].to_i

    DateTime.new(year, month, day, hour, min)
  end

  def event_params
    params[:event][:cost] = params[:event][:cost_in_dollars].to_i * 100 if params[:event][:cost_in_dollars]
    params.require(:event).permit(
      :title,
      :host,
      :cost,
      :description,
      :city,
      :token,
      :color,
      :zip,
      :date,
      :address,
      :location_instructions,
      :class_name
    )
  end

  def validate_user
    unless user_signed_in? && current_user.role > 1
      flash[:alert] = "You are not permitted to create Events."
      redirect_to root_path
    end
  end
end
