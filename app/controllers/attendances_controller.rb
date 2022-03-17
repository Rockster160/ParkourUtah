class AttendancesController < ApplicationController
  before_action :validate_admin, except: [ :index ]
  before_action :validate_instructor, only: [ :index ]
  before_action :set_date, only: [ :new, :create ]
  before_action :set_attendance_and_event, only: [ :new, :create ]
  before_action :set_events_from_date

  def index
    @attendances = Attendance.by_most_recent(:created_at).page(params[:page])
  end

  def new
  end

  def create
    if @event.present? && @event.valid? && @event.save && @attendance.valid? && @attendance.save
      @attendance.update_attribute(created_at: @event.date.end_of_day)
      redirect_to attendances_path, notice: "Successfully added Student to Class"
    else
      redirect_to new_attendance_path(attendance: passable_attributes_for_attendance, errors: @attendance.errors.full_messages + (@event&.errors&.full_messages || []))
    end
  end

  def destroy
    attendance = Attendance.find(params[:id])
    if attendance.destroy
      redirect_back fallback_location: attendances_path, notice: "Successfully destroyed the Attendance."
    else
      redirect_back fallback_location: attendances_path, alert: "Failed to destroy the Attendance"
    end
  end

  private

  def set_events_from_date
    return unless @date.present? && @date.respond_to?(:hour)
    @events = EventSchedule.events_for_date(@date)
    @events.each(&:save)
    @attendance.event_date = @date
  end

  def set_attendance_and_event
    @event = Event.find_by_id(params.dig(:attendance, :event_id))
    @attendance = Attendance.new(attendance_params)
    @errors = params[:errors]
  end

  def set_date
    begin
      @date = Time.zone.parse(params[:date] || params.dig(:attendance, :event_date))
    rescue StandardError
      @date = nil
    end
  end

  def passable_attributes_for_attendance
    @attendance.attributes.symbolize_keys.slice(:athlete_id, :instructor_id, :event_id, :type_of_charge).merge({
      event_date: @attendance.event_date,
    }).reject { |attr_key, attr_val| attr_val.nil? }
  end

  def attendance_params
    temp_params = params[:attendance] || params
    temp_params.permit([
      :athlete_id,
      :instructor_id,
      :event_id,
      :type_of_charge,
      # Temp params
      :event_date,
    ])
  end

end
