class CalendarController < ApplicationController
  include ApplicationHelper
  skip_before_action :verify_authenticity_token

  def show
    redirect_to calendar_mobile_path if mobile_check && params[:desktop] != 'true'

    @date = rails_time_from(params[:date])
    @week = (@date.beginning_of_week(:sunday)..@date.end_of_week(:sunday))

    set_city_lists
  end

  def get_week
    @date = rails_time_from(params[:date])

    @date -= 1.week if params[:direction] == 'previous'
    @date += 1.week if params[:direction] == 'next'
    @date += 1.day if @date.wday == 0

    @week = (@date.beginning_of_week(:monday)..@date.end_of_week(:sunday))

    set_city_lists

    respond_to do |format|
      if params[:size] == 'mobile'
        format.js { render partial: 'mobile_week'}
      else
        format.js { render partial: 'desktop_week'}
      end
    end
  end

  def mobile
    @date = parse_date(params[:date]) || Time.zone.now
    @week = (@date.beginning_of_week(:sunday)..@date.end_of_week(:sunday))
  end

  # mm-dd-yyyy : From Rails
  # yyyy-mm-dd : From Javascript
  def rails_time_from(date)
    return Time.zone.now if date == 'undefined' || date.blank?
    a, b, c = date.split('-')
    day, month, year = a.length == 4 ? [c, b, a] : [b, a, c]
    begin
      Time.zone.local(year.to_i, month.to_i, day.to_i)
    rescue
      Time.zone.now
    end
  end

  private

  def set_city_lists
    all_events = EventSchedule.in_the_future.order(:start_date)
    @events = all_events
    @cities = all_events.pluck(:city).uniq.map(&:parameterize)
    @classes = all_events.pluck(:title).uniq.map(&:parameterize)

    @selected_cities = params[:cities].blank? ? @cities : params[:cities]
    @selected_classes = params[:classes].blank? ? @classes : params[:classes]
  end

  def mobile_check
    browser = Browser.new(request.user_agent)
    if browser.known?
      return browser.device.mobile?
    else
      if session[:mobile_param]
        return session[:mobile_param] == "1"
      else
        return !!(request.user_agent =~ /Mobile|webOS/)
      end
    end
  end

end
