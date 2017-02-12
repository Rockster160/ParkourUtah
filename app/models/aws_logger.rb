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

  after_create :parse_log

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

end
