class CalendarController < ApplicationController
  include ApplicationHelper

  def show
    redirect_to calendar_mobile_path if mobile_check && params[:desktop] != 'true'

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
      Date.today
    else
      params[:date] ? (rails_time_from(params[:date]) || Date.today) : Date.today
    end
    
    @date -= 1.week if params[:direction] == 'previous'
    @date += 1.week if params[:direction] == 'next'
    @date += 1.day if @date.wday == 0

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
    @date = parse_date(params[:date]) || Date.today
    @week = (@date.beginning_of_week(:sunday)..@date.end_of_week(:sunday))
  end

  # mm-dd-yyyy : From Rails
  # yyyy-mm-dd : From Javascript
  def rails_time_from(date)
    a, b, c = date.split('-')
    day, month, year = a.length == 4 ? [c, b, a] : [b, a, c]
    DateTime.new(year.to_i, month.to_i, day.to_i)
  end

  private

  def mobile_check
    browser = Browser.new
    if browser.known?
      return browser.mobile?
    else
      if session[:mobile_param]
        return session[:mobile_param] == "1"
      else
        return !!(request.user_agent =~ /Mobile|webOS/)
      end
    end
  end

end
