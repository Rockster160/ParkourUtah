class EventsController < ApplicationController
  before_action :set_event_schedule

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
    event = @event_schedule.event_by_id(params[:id], with_date: params[:date])
    event.save
    if params[:should_happen] == "true"
      event.uncancel!
      flash[:notice] = "Event has successfully been uncancelled."
    else
      event.cancel!
      flash[:notice] = "Event has successfully been cancelled."
    end
    redirect_to :back
  end

  private

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
