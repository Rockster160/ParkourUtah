class IndexController < ApplicationController
  def index
    @date = params[:date] ? Date.parse(params[:date]) : Date.today
    @events = Event.all.to_a.group_by { |event| [event.date.month, event.date.day] }
    @cities = %w[ Sandy Draper Salt\ Lake\ City Lehi Orem Provo Murray Holladay South\ Jordan ]
  end
end
