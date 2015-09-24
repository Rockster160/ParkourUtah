class CalendarController < ApplicationController
  include ApplicationHelper

  def index
  end

  def show
    @date = params[:date] ? rails_time_from(params[:date]) : Date.today
    @week = (@date.beginning_of_week(:monday)..@date.end_of_week(:sunday))

    all_events = Event.all.to_a
    @events = all_events.group_by { |event| [event.date.year, event.date.month, event.date.day] }
    @cities = all_events.group_by { |event| event.city }.keys.sort.map(&:parameterize)
    @classes = all_events.group_by { |event| event.class_name }.keys.sort.map(&:parameterize)

    @selected_cities = params[:cities] ? params[:cities] : @cities
    @selected_classes = params[:classes] ? params[:classes] : @classes
  end

  def get_week
    @date = if params[:date] == 'undefined'
      DateTime.current
    else
      rails_time_from(params[:date]) || DateTime.current
    end
    @date -= 1.week if params[:direction] == 'previous'
    @date += 1.week if params[:direction] == 'next'

    @week = (@date.beginning_of_week(:monday)..@date.end_of_week(:sunday))

    all_events = Event.all.to_a
    @events = all_events.group_by { |event| [event.date.year, event.date.month, event.date.day] }
    @cities = all_events.group_by { |event| event.city }.keys.sort.map(&:parameterize)
    @classes = all_events.group_by { |event| event.class_name }.keys.sort.map(&:parameterize)

    @selected_cities = params[:cities] ? params[:cities] : @cities
    @selected_classes = params[:classes] ? params[:classes] : @classes

    respond_to do |format|
      if params[:size] == 'mobile'
        format.js { render partial: 'mobile_week'}
      else
        format.js { render partial: 'desktop_week'}
      end
    end
  end

  def mobile
    @date = parse_date(params[:date]) || DateTime.current
    @week = (@date.beginning_of_week(:sunday)..@date.end_of_week(:sunday))
  end

  # mm-dd-yyyy
  def rails_time_from(date)
    month = date[0..1].to_i
    day = date[3..4].to_i
    year = date[6..10].to_i
    DateTime.new(year, month, day)
  end
end
