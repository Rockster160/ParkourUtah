class AttendancesController < ApplicationController

  def index
    @attendances = Attendance.order(created_at: :desc).page(params[:page])
  end

end
