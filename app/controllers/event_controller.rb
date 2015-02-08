class EventController < ApplicationController
  before_action :validate_user, only: [ :create, :new ]
  # vefore_action :authenticate_mod/admin only: { :create, :delete }
  # https://github.com/plataformatec/devise#strong-parameters

  def show
    @event = Event.find(params[:id])
  end

  def new
    @event = Event.new
    all_events = Event.all.to_a
    @cities = all_events.group_by { |event| event.city }.keys
    @classes = all_events.group_by { |event| event.class_name }.keys
    @mods = User.where("role > ?", 0)
  end

  def create
    date_time = convertToRailsTime(params[:date], params[:time])
    dates = []
    iterate = params[:repeat] ? 50 : 1
    iterate.times do |each_week|
      dates << date_time + (each_week.weeks)
    end
    dates.each do |date|
      params[:event][:date] = date
      Event.create(event_params)
    end
    redirect_to calendar_show_path("all")
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
    params.require(:event).permit(:title, :host_id, :cost, :description, :city,
                              :date, :address, :location_instructions, :class_name)
  end

  def validate_user
    unless user_signed_in? && current_user.role > 0
      flash[:error] = "You are not permitted to create Events."
      redirect_to root_path
    end
  end
end
