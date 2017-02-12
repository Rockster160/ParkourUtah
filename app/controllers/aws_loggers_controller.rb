class AwsLoggersController < ApplicationController
  before_action :validate_admin

  def index
    @loggers = AwsLogger.order(time: :desc)
      .parsed
      .sent_bytes
      .by_operation("GET")
      .page(params[:page])
      .per(300)
  end

  def show
    @logger = AwsLogger.find(params[:id])
  end

end
