class ClassHandlersController < ApplicationController
  before_action :validate_instructor
  before_action :set_event_schedule

  def athlete_id
    if @event_schedule.present?
      @event = @event_schedule.event_by_id(params[:id], with_date: params[:date])
    else
      @event = Event.find(params[:id])
    end
    @event.save unless @event.persisted?
  end

  def athlete_pin
    @event = Event.find(params[:id])
    if params[:athlete_id].to_i == 0
      return redirect_to dashboard_path
    elsif params[:athlete_id] == ENV["PKUT_PIN"]
      return redirect_to logs_class_handler_path(@event)
    end
    @athlete = Dependent.where(athlete_id: params[:athlete_id].to_i).first
    return redirect_to(athlete_id_class_handler_path(@event), alert: "No athlete found.") if @athlete.nil?
    return redirect_to(athlete_id_class_handler_path(@event), alert: "#{@athlete.full_name} already attending class.") if @athlete.attendances.where(event_id: @event.id).any?
  end

  def join_class
    @event = Event.find(params[:id])
    @athlete = Dependent.where(athlete_id: params[:athlete_id].to_i).first
    if @athlete.nil?
      flash[:alert] = "No athlete found."
    elsif @athlete.valid_athlete_pin?(params[:athlete_pin])
      flash[:alert] = "Incorrect Athlete Pin."
    elsif !@athlete.attend_class(@event, current_user)
      if @athlete.attendances.where(event_id: @event.id).any?
        flash[:alert] = "Athlete is already attending class."
      elsif @athlete.user.credits <= @event.cost_in_dollars
        flash[:alert] = "Insufficient credits in account."
      else
        SlackNotifier.notify("Failed to add athlete: #{@athlete.id}: #{@athlete.full_name}", "#server-errors")
        flash[:alert] = "Failed to add Athlete to class."
      end
    else
      flash[:notice] = "Athlete successfully added to class!"
    end
    redirect_to athlete_id_class_handler_path(@event)
  end

  def logs
    @event = Event.find(params[:id])
    @attendances = @event.attendances
  end

  private

  def set_event_schedule
    @event_schedule = EventSchedule.find(params[:event_schedule_id]) if params[:event_schedule_id].present?
  end

end
