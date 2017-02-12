class AttendancesController < ApplicationController
  before_action :validate_instructor

  def index
    @attendances = Attendance.order(created_at: :desc).page(params[:page])
  end

end
