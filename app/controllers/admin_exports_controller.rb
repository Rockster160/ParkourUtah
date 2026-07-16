require "csv"

class AdminExportsController < ApplicationController
  before_action :still_signed_in
  before_action :validate_admin

  OUTPUT_FORMATS = %w[csv emails phones].freeze

  # Available CSV columns, in the order they should appear if selected.
  # Add a new one by: appending here, adding a case branch in `cell_for`,
  # and adding a checkbox in the view.
  CSV_COLUMNS = %i[
    account_url
    user_id
    email
    full_name
    phone_number
    credits
    signed_up_at
    last_sign_in_at
    last_attendance_at
    athletes
  ].freeze

  DEFAULT_CSV_COLUMNS = %i[account_url email phone_number athletes].freeze

  CSV_COLUMN_LABELS = {
    account_url:        "Account",
    user_id:            "User ID",
    email:              "Email",
    full_name:          "Name",
    phone_number:       "Phone Number",
    credits:            "Credits",
    signed_up_at:       "Signed Up",
    last_sign_in_at:    "Last Sign In",
    last_attendance_at: "Last Attendance",
    athletes:           "Athletes",
  }.freeze

  def index
    @query = UserExportQuery.new(export_params)
    @event_schedules = EventSchedule.order(:day_of_week, :hour_of_day, :title)
    @submitted = params[:action_type].present?
    @selected_columns = selected_columns

    return unless @submitted

    @count = @query.count

    case params[:action_type]
    when "preview"
      # Just show the count.
    when "export"
      case output_format
      when "csv"
        send_data build_csv, filename: csv_filename, type: "text/csv"
      when "emails"
        @output_label = "Emails"
        @output_text  = @query.users.pluck(:email).map(&:to_s).reject(&:blank?).uniq.join(", ")
      when "phones"
        @output_label = "Phone numbers"
        @output_text  = @query.users.pluck(:phone_number).map { |p| helpers.strip_phone_number(p) }.compact.uniq.join(", ")
      end
    end
  end

  private

  def export_params
    scalar_keys = UserExportQuery::KNOWN_PARAMS - %i[event_schedule_ids weekdays]
    params.permit(*scalar_keys, event_schedule_ids: [], weekdays: []).to_h.symbolize_keys
  end

  def output_format
    fmt = params[:output_format].to_s
    OUTPUT_FORMATS.include?(fmt) ? fmt : "csv"
  end

  def selected_columns
    return DEFAULT_CSV_COLUMNS unless @submitted
    picked = CSV_COLUMNS & Array(params[:columns]).map(&:to_sym)
    picked.presence || DEFAULT_CSV_COLUMNS
  end

  def csv_filename
    "users_export_#{Date.current.strftime('%Y%m%d')}.csv"
  end

  def build_csv
    columns = @selected_columns
    last_attendance_by_user =
      if columns.include?(:last_attendance_at)
        Attendance.joins(:athlete)
                  .where(athletes: { user_id: @query.users.select(:id) })
                  .group("athletes.user_id")
                  .maximum("attendances.created_at")
      else
        {}
      end

    CSV.generate do |csv|
      csv << columns.map { |c| CSV_COLUMN_LABELS[c] }
      @query.users.includes(:athletes).find_each do |user|
        csv << columns.map { |c| cell_for(c, user, last_attendance_by_user) }
      end
    end
  end

  def cell_for(column, user, last_attendance_by_user)
    case column
    when :account_url        then admin_user_url(user, host: request.host, protocol: request.protocol, port: request.port)
    when :user_id            then user.id
    when :email              then user.email
    when :full_name          then user.full_name
    when :phone_number       then user.phone_number
    when :credits            then user.credits
    when :signed_up_at       then fmt_date(user.created_at)
    when :last_sign_in_at    then fmt_datetime(user.last_sign_in_at)
    when :last_attendance_at then fmt_datetime(last_attendance_by_user[user.id])
    when :athletes           then user.athletes.map(&:full_name).join("\n")
    end
  end

  def fmt_date(t)
    t&.in_time_zone&.to_formatted_s(:simple)
  end

  def fmt_datetime(t)
    t&.in_time_zone&.to_formatted_s(:simple_with_time)
  end
end
