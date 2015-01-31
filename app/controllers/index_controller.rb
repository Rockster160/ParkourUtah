class IndexController < ApplicationController
  def index
    @date = params[:date] ? Date.parse(params[:date]) : Date.today
    all_events = Event.all.to_a
    
    @events = all_events.group_by { |event| [event.date.month, event.date.day] }
    @cities = all_events.group_by { |event| event.city }.keys
    @classes = all_events.group_by { |event| event.class_name }.keys - ["special"]
  end
end
