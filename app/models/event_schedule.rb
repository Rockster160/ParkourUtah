# == Schema Information
#
# Table name: event_schedules
#
#  id              :integer          not null, primary key
#  instructor_id   :integer
#  spot_id         :integer
#  start_date      :datetime
#  end_date        :datetime
#  hour_of_day     :integer
#  minute_of_day   :integer
#  day_of_week     :integer
#  cost_in_pennies :integer
#  title           :string
#  description     :text
#  full_address    :string
#  city            :string
#  color           :string
#  created_at      :datetime
#  updated_at      :datetime
#

class EventSchedule < ActiveRecord::Base

  belongs_to :instructor, class_name: "User"
  belongs_to :spot
  has_many :events
  has_many :attendances, through: :events
  has_many :subscriptions, dependent: :destroy
  has_many :subscribed_users, through: :subscriptions, class_name: "User"

  scope :in_the_future, -> { where("start_date < :now AND (end_date IS NULL OR end_date > :now)", now: Time.zone.now) }

  enum day_of_week: {
    sunday: 0,
    monday: 1,
    tuesday: 2,
    wednesday: 3,
    thursday: 4,
    friday: 5,
    saturday: 6,
  }

  def self.events_today
    events_for_date(Time.zone.now)
  end
  def self.events_for_date(day)
    events_in_date_range(day, day)
  end
  def self.events_in_date_range(first_day, last_day)
    first_day, last_day = first_day.to_datetime, last_day.to_datetime
    time_zone = Time.zone
    first_date = time_zone.local(first_day.year, first_day.month, first_day.day, first_day.hour, first_day.minute).beginning_of_day
    last_date = time_zone.local(last_day.year, last_day.month, last_day.day, last_day.hour, last_day.minute).end_of_day
    scheduled = where("start_date < :first_date AND (end_date IS NULL OR end_date > :last_date)", first_date: first_date, last_date: last_date)
    scheduled.map do |schedule|
      scheduled_events = schedule.events.where(date: first_date..last_date)
      scheduled_events.empty? ? schedule.new_events_for_time_range(first_date, last_date) : scheduled_events
    end.flatten.compact
  end

  def time_of_day
    meridiam = hour_of_day > 12 ? "PM" : "AM"
    adjusted_hour = hour_of_day > 12 ? hour_of_day - 12 : hour_of_day
    "#{adjusted_hour.to_s}:#{minute_of_day.to_s.rjust(2, '0')} #{meridiam}"
  end

  def host_name
    instructor.try(:full_name)
  end

  def event_by_id(new_or_id, options={})
    if new_or_id == "new"
      options[:additional_params] ||= {}
      options[:additional_params][:date] = Time.zone.local(*options[:with_date].split('-').map(&:to_i)) if options[:with_date]
      events.new(date: options.merge(options[:additional_params] || {}))
    else
      events.find(new_or_id)
    end
  end

  def new_events_for_time_range(first_date=start_date, last_date=end_date)
    raise 'Must have an end date' unless last_date.present?
    current_date = (first_date + days_until_next_week_day_from(first_date))
    new_events = []
    until current_date > last_date
      new_events << events.new(date: current_date)
      current_date += 7.days
    end
    new_events
  end

  def days_until_next_week_day_from(from_date)
    to_week_day = EventSchedule.day_of_weeks[day_of_week]
    day_count = (to_week_day - from_date.wday) % 7
    day_count.days
  end

end
