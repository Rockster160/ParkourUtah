class EventsController < ApplicationController
  before_action :set_event_schedule

  def show
    if params[:event_schedule_id].present?
      @event = @event_schedule.event_by_id(params[:id], with_date: params[:date])
    else
      @event = Event.find(params[:id])
    end
  end

  def edit
    @event = @event_schedule.event_by_id(params[:id], with_date: params[:date])
    @event.save
  end

  def update
    @event = Event.find(params[:id])
    if @event.update_date(event_params)
      redirect_to calendar_show_path(date: @event.date.strftime("%m-%d-%Y")), notice: "Successfully updated event date."
    else
      redirect_to calendar_show_path(date: @event.date.strftime("%m-%d-%Y")), alert: "Failed to update Event."
    end
  end

  def detail
    @event = @event_schedule.event_by_id(params[:id], with_date: params[:date])
    respond_to do |format|
      format.html { render layout: !request.xhr? }
    end
  end

  def cancel
    if params[:id] == "new"
      event = @event_schedule.event_by_id(params[:id], with_date: params[:date])
      event.save
    else
      event = Event.find(params[:id])
    end
    if params[:should_happen] == "true"
      event.uncancel!
      flash[:notice] = "Event has successfully been uncancelled."
    else
      event.cancel!
      flash[:notice] = "Event has successfully been cancelled."
    end
    redirect_to calendar_show_path(date: event.date.strftime("%m-%d-%Y"))
  end

  private

  def event_params
    params.require(:event).permit(:str_date, :time_of_day)
  end

  def set_event_schedule
    @event_schedule = EventSchedule.find(params[:event_schedule_id]) if params[:event_schedule_id].present?
  end

  def validate_mod
    unless user_signed_in? && current_user.is_mod?
      flash[:alert] = "You are not permitted to create Events."
      redirect_to root_path
    end
  end
end
