# == Schema Information
#
# Table name: aws_loggers
#
#  id                     :integer          not null, primary key
#  orginal_string         :text
#  bucket_owner           :string
#  bucket                 :string
#  time                   :datetime
#  remote_ip              :string
#  requester              :string
#  request_id             :string
#  operation              :string
#  key                    :string
#  request_uri            :string
#  http_status            :string
#  error_code             :string
#  bytes_sent             :integer
#  object_size            :integer
#  total_time             :integer
#  turn_around_time       :integer
#  referrer               :string
#  user_agent             :string
#  version_id             :string
#  set_all_without_errors :boolean
#

class AwsLogger < ActiveRecord::Base
  include ActionView::Helpers::NumberHelper
  include ApplicationHelper

  after_create :parse_log

  scope :log_requests, -> { where("request_uri ILIKE ?", "%logs%") }
  scope :by_operation, ->(operation) { where("operation ILIKE ?", "%#{operation}%") }
  scope :parsed, -> { where(set_all_without_errors: true) }
  scope :sent_bytes, -> { where("bytes_sent > 0") }

  validate :not_log_request

  def parse_log
    return unless orginal_string.present?
    split_log = escape_white_space(orginal_string).split(" ")
    @temp_attributes = {
      bucket_owner: split_log[0],
      bucket: split_log[1],
      time: split_log[2],
      remote_ip: split_log[3],
      requester: split_log[4],
      request_id: split_log[5],
      operation: split_log[6],
      key: split_log[7],
      request_uri: split_log[8],
      http_status: split_log[9],
      error_code: split_log[10],
      bytes_sent: split_log[11],
      object_size: split_log[12],
      total_time: split_log[13],
      turn_around_time: split_log[14],
      referrer: split_log[15],
      user_agent: split_log[16],
      version_id: split_log[17]
    }
    clean_up_styles
    parse_time
    check_if_all_set
    self.assign_attributes(@temp_attributes)
    self.save
  end

  def is_log_request?
    request_uri.to_s.include?("logs")
  end

  def clean_up_styles
    @temp_attributes.each do |temp_attr, temp_val|
      @temp_attributes[temp_attr] = temp_val.gsub("%20", " ")
      @temp_attributes[temp_attr] = @temp_attributes[temp_attr] == "-" ? "N/A" : @temp_attributes[temp_attr]
    end
  end

  def escape_white_space(str)
    replace_white_space = str.gsub(/".*?"/) do |found|
      found.gsub(" ", "%20")
    end.gsub('"', "")
    replace_time_brackets = replace_white_space.gsub(/\[.*?\]/) do |found|
      found.gsub(" ", "%20")
    end
    replace_time_brackets
  end

  def parse_time
    str_time = @temp_attributes[:time]
    return unless str_time.present?
    @temp_attributes[:time] = DateTime.strptime(str_time[1..-2], "%d/%b/%Y:%H:%M:%S %z") rescue nil
  end

  def check_if_all_set
    @temp_attributes[:set_all_without_errors] = @temp_attributes.except("id", "set_all_without_errors").all?
    unless @temp_attributes[:set_all_without_errors]
      SlackNotifier.notify("*Failed to parse log file!*\n```#{orginal_string}```", "#server-errors")
    end
  end

  def displayable_attributes
    {
      bucket_owner: self.bucket_owner,
      bucket: self.bucket,
      time: "#{self.time.strftime('%b %-d, %Y %-l:%M:%S %p')}",
      remote_ip: self.remote_ip,
      requester: self.requester,
      request_id: self.request_id,
      operation: self.operation,
      key: self.key,
      request_uri: self.request_uri,
      http_status: "#{self.http_status.presence || 'Unknown'} (#{Rack::Utils::HTTP_STATUS_CODES[self.http_status.to_i].presence || 'Unknown'})",
      error_code: self.error_code,
      bytes_sent: "#{number_to_human_size(self.bytes_sent, precision: 3)} (#{self.bytes_sent} bytes)",
      object_size: "#{number_to_human_size(self.object_size, precision: 3)} (#{self.object_size} bytes)",
      total_time: humanize_seconds(self.total_time).presence || "0 milliseconds",
      turn_around_time: humanize_seconds(self.turn_around_time).presence || "0 milliseconds",
      referrer: self.referrer,
      user_agent: self.user_agent,
      version_id: self.version_id,
      orginal_string: self.orginal_string,
    }
  end

  def not_log_request
    if is_log_request?
      errors.add(:base, "Don't save Logs.")
    end
  end

end
