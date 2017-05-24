class LogTrackersController < ApplicationController
  before_action :validate_admin

  def index
    @loggers = LogTracker.order(created_at: :desc).page(params[:page])
  end

  def show
    @logger = LogTracker.find(params[:id])
  end

end
