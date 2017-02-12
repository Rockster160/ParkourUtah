class AwsLoggersController < ApplicationController
  include ParamsHelper
  helper ParamsHelper

  before_action :validate_admin

  def index
    params[:sort] ||= "time"
    params[:order] ||= "desc"

    @loggers = AwsLogger.parsed
      .sent_bytes
      .by_operation("GET")
      .page(params[:page])
      .per(100)

    # @loggers = case params[:sort]
    # when "bytes_sent" then @loggers.order("bytes_sent #{sort_order}")
    # else @loggers.order(time: :desc)
    # end
    #
    # @loggers = case params[:group]
    # else @loggers.group_by { |l| l.time.to_date }.map {|k,vs|[k.strftime("%B %-d, %Y"), vs]}.to_h
    # end
  end

  def show
    @logger = AwsLogger.find(params[:id])
  end

end
