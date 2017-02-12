class AwsLoggersController < ApplicationController
  include ParamsHelper
  helper ParamsHelper

  before_action :validate_admin

  def index
    params[:sort] ||= "time"
    params[:order] ||= "desc"

    @current_filter = params.to_hash.symbolize_keys.slice(:group, :sort, :order, :page)

    @loggers = AwsLogger.parsed.objects
      .with_sent_bytes
      .page(params[:page])
      .per(100)

    @loggers = case params[:sort]
    when "bytes_sent" then @loggers.order("bytes_sent #{sort_order}")
    else @loggers.order(time: :desc)
    end

    @grouped_loggers = case params[:group]
    when "remote_ip" then @loggers.group_by { |l| l.remote_ip }
    else @loggers.group_by { |l| l.time.to_date }.map {|k,vs|[k.strftime("%B %-d, %Y"), vs]}.to_h
    end
  end

  def show
    @logger = AwsLogger.find(params[:id])
  end

end
