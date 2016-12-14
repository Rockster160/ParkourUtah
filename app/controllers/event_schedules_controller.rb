class EventSchedulesController < ApplicationController
  before_action :validate_user, only: [ :create, :new ]

  def index
    @event_schedules = EventSchedule.in_the_future
  end

  def new
    @event_schedule = EventSchedule.new(city: params[:city])
  end

  def edit
    @event_schedule = EventSchedule.find(params[:id])
  end

  def update
    @event_schedule = EventSchedule.find(params[:id])
    if @event_schedule.update(event_schedule_params)
      redirect_to event_schedules_path, notice: "Success!"
    else
      flash.now[:alert] = "Failed."
      render :edit
    end
  end

  def create
    @event_schedule = EventSchedule.new(event_schedule_params)
    if @event_schedule.save
      redirect_to event_schedules_path, notice: "Success!"
    else
      flash.now[:alert] = "Failed."
      render :new
    end
  end

  def subscribe
    user = params[:user_id].present? ? User.find(params[:user_id]) : current_user
    user.subscriptions.create(event_schedule_id: params[:id])
    flash[:notice] = "You have successfully subscribed to this event."
    redirect_to :back
  end

  def unsubscribe
    user = params[:user_id].present? ? User.find(params[:user_id]) : current_user
    user.subscriptions.where(event_schedule_id: params[:id]).destroy_all
    flash[:notice] = "You have successfully unsubscribed from this event."
    redirect_to :back
  end

  private

  def validate_user
    unless user_signed_in? && current_user.is_admin?
      flash[:alert] = "You are not permitted to create Events."
      redirect_to root_path
    end
  end

  def event_schedule_params
    params.require(:event_schedule).permit(
      :instructor_id,
      :spot_id,
      :start_str_date,
      :end_str_date,
      :time_of_day,
      :day_of_week,
      :cost,
      :title,
      :description,
      :full_address,
      :city,
      :color
    )
  end

end
