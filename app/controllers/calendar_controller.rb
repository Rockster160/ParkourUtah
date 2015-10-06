class CalendarController < ApplicationController
  include ApplicationHelper

  def show
    @date = params[:date] ? Date.parse(params[:date]) : Date.today

    all_events = Event.all.to_a
    @events = all_events.group_by { |event| [event.date.year, event.date.month, event.date.day] }
    @cities = all_events.group_by { |event| event.city }.keys.sort
    @classes = all_events.group_by { |event| event.class_name }.keys

    @selected_cities = params[:cities] ? params[:cities] : @cities
    @selected_classes = params[:classes] ? params[:classes] : @classes
  end

  def get_week
    @date = params[:date].to_date || DateTime.current

    if params[:direction] == 'previous'
      @date -= 1.week
    elsif params[:direction] == 'next'
      @date += 1.week
    end
    @week = (@date.beginning_of_week(:sunday)..@date.end_of_week(:sunday))

    respond_to do |format|
      format.js { render partial: 'week'}
    end
  end

  def draw
    @date = params[:date] ? Date.parse(params[:date]) : Date.today

    all_events = Event.all.to_a
    @events = all_events.group_by { |event| [event.date.year, event.date.month, event.date.day] }
    @cities = all_events.group_by { |event| event.city }.keys.sort
    @classes = all_events.group_by { |event| event.class_name }.keys

    @selected_cities = params[:cities] ? params[:cities] : @cities
    @selected_classes = params[:classes] ? params[:classes] : @classes
    respond_to do |format|
      format.js
    end
  end

  def mobile
    @date = parse_date(params[:date]) || DateTime.current
    @week = (@date.beginning_of_week(:sunday)..@date.end_of_week(:sunday))
  end
end
