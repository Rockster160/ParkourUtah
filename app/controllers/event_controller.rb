class EventController < ApplicationController
  before_action :validate_user, only: [ :create, :new ]
  # vefore_action :authenticate_instructor/admin only: { :create, :delete }
  # https://github.com/plataformatec/devise#strong-parameters

  def show
    @event = Event.find(params[:id])
  end

  def new
    @event = Event.new
    all_events = Event.all.to_a
    @cities = all_events.group_by { |event| event.city }.keys
    @classes = all_events.group_by { |event| event.class_name }.keys
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
    redirect_to calendar_show_path("all")
  end

  def destroy
    if params[:future]
      event = Event.find(params[:id])
      token = event.token
      date = event.date
      Event.where("token = :token AND date > :date", token: token, date: date).each do |event|
        event.destroy
      end
    else
      Event.find(params[:id]).destroy
    end
    redirect_to calendar_show_path("all")
  end

  def subscribe
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
    params.require(:event).permit(:title, :host, :cost, :description, :city, :token,
                              :date, :address, :location_instructions, :class_name)
  end

  def validate_user
    unless user_signed_in? && current_user.role > 1
      flash[:error] = "You are not permitted to create Events."
      redirect_to root_path
    end
  end
end
