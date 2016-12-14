class EventsController < ApplicationController
  before_action :set_event_schedule
  before_action :validate_user, only: [ :create, :new ]

  def index
    @events = Event.sort_by_token
  end

  def show
    @event = @event_schedule.event_by_id(params[:id], with_date: params[:date])
  end

  def detail
    @event = @event_schedule.event_by_id(params[:id], with_date: params[:date])
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
    all_events = EventSchedule.in_the_future.order(:start_date)
    @cities = all_events.pluck(:city).uniq
    @classes = all_events.pluck(:title).uniq
    @instructors = User.where("role > ?", 0)
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
    redirect_to calendar_show_path
  end

  def edit
    @event = params[:id] == "new" ? Event.new(event_schedule_id: params[:event_schedule_id]) : Event.find(params[:id])
  end

  def update
    event = Event.find(params[:id])
    hour = params[:time][:meridiam] == "AM" ? params[:time][:hour].to_i : params[:time][:hour].to_i + 12
    min = params[:time][:minute].to_i
    params[:event][:date] = event.date.change({hour: hour, min: min})
    # FIXME on update, 'cancel' the original instance and create a new instance - so we don't have a duplicate event if the date/time changes
    event.update(event_params)
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
    redirect_to calendar_show_path
  end

  private

  def set_event_schedule
    @event_schedule = EventSchedule.find(params[:event_schedule_id]) if params[:event_schedule_id].present?
  end

  def convertToRailsTime(date, time)
    new_date = date.split("/")

    year = new_date[2].to_i
    month = new_date[0].to_i
    day = new_date[1].to_i
    hour = time[:meridiam] == "AM" ? time[:hour].to_i : time[:hour].to_i + 12
    min = time[:minute].to_i

    Time.zone.local(year, month, day, hour, min)
  end

  def event_params
    params[:event][:cost] = params[:event][:cost_in_dollars].to_i * 100 if params[:event][:cost_in_dollars]
    params.require(:event).permit(
      :title,
      :instructor_id,
      :cost,
      :description,
      :city,
      :token,
      :color,
      :zip,
      :date,
      :address,
      :location_instructions,
      :title,
      :spot_id
    )
  end

  def validate_user
    unless user_signed_in? && current_user.role > 1
      flash[:alert] = "You are not permitted to create Events."
      redirect_to root_path
    end
  end
end
