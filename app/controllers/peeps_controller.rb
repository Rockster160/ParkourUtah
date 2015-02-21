class PeepsController < ApplicationController

  def show
    @instructor = User.find(params[:id])
    redirect_to root_path unless @instructor.is_instructor?
  end
end
