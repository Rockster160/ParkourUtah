class CalendarController < ApplicationController
  def index
  end

  def day
    @events = Event.all.to_a.group_by { |event| event.date.strftime('%Y-%m-%d') }[params[:date]]
  end

  def draw
    @date = params[:date] ? Date.parse(params[:date]) : Date.today

    all_events = Event.all.to_a
    @events = all_events.group_by { |event| [event.date.year, event.date.month, event.date.day] }
    @cities = all_events.group_by { |event| event.city }.keys
    @classes = all_events.group_by { |event| event.class_name }.keys

    @selected_cities = params[:cities] ? params[:cities] : @cities
    @selected_classes = params[:classes] ? params[:classes] : @classes
    respond_to do |format|
      format.js
    end
  end
end
