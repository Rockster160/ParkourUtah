class CalendarController < ApplicationController
  def index
    @date = params[:date] ? Date.parse(params[:date]) : Date.today
  end

  def show

  end
end
