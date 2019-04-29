# == Schema Information
#
# Table name: event_reminders
#
#  id                       :integer          not null, primary key
#  event_schedule_id        :integer
#  relative_time_difference :integer
#  message                  :text
#

class EventReminder < ApplicationRecord
  include Defaults
  belongs_to :event_schedule

  default_on_create relative_time_difference: 2.hours
end
