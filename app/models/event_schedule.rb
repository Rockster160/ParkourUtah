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

class EventSchedule < ApplicationRecord
  include Defaults

  belongs_to :instructor, class_name: "User"
  belongs_to :spot, optional: true
  has_many :events
  has_many :attendances, through: :events
  has_many :subscriptions, dependent: :destroy
  has_many :subscribed_users, through: :subscriptions, source: :user

  before_save :add_hash_to_colors

  default_on_create :color, "##{6.times.map { rand(16).to_s(16) }.join('')}"
  default_on_create :payment_per_student, 4
  default_on_create :min_payment_per_session, 15

  validates :start_date, :hour_of_day, :minute_of_day, :day_of_week, :cost_in_pennies, :title, :city, :color, presence: true
  validate :has_either_address_or_spot
  validate :has_at_least_one_payment_rule

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
      scheduled_events = schedule.events.where(original_date: first_date..last_date)
      scheduled_events.empty? ? schedule.new_events_for_time_range(first_date, last_date) : scheduled_events.where(date: first_date..last_date)
    end.flatten.compact
  end

  def cost=(amount_in_dollars)
    self.cost_in_pennies = amount_in_dollars.to_f * 100
  end
  def cost; cost_in_dollars; end
  def cost_in_dollars; cost_in_pennies.to_f / 100.to_f; end

  def start_str_date; start_date.present? ? start_date.strftime('%b %d, %Y') : nil; end
  def start_str_date=(new_date)
    self.start_date = Time.zone.parse(new_date) rescue nil
  end
  def end_str_date; end_date.present? ? end_date.strftime('%b %d, %Y') : nil; end
  def end_str_date=(new_date)
    self.end_date = Time.zone.parse(new_date) rescue nil
  end

  def time_of_day=(new_time_str)
    return nil if new_time_str.split(":")[0].to_i <= 12 && (new_time_str =~ /(a|p)m/i).nil?
    time = Time.zone.parse(new_time_str) rescue nil
    self.hour_of_day = time.try(:hour)
    self.minute_of_day = time.try(:min)
  end
  def time_of_day
    hour_of_day = self.hour_of_day || 17
    minute_of_day = self.minute_of_day || 0
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
      options[:additional_params][:date] = Time.zone.parse(options[:with_date]) if options[:with_date]
      events.new(options[:additional_params])
    else
      events.find(new_or_id)
    end
  end

  def new_events_for_time_range(first_date=start_date, last_date=end_date)
    raise 'Must have an end date' unless last_date.present?
    first_date_with_time = Time.zone.local(first_date.year, first_date.month, first_date.day, hour_of_day, minute_of_day)
    current_date = (first_date_with_time + days_until_next_week_day_from(first_date))
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

  private

  def add_hash_to_colors
    color.prepend('#') if color.present? && (color.length == 3 || color.length == 6)
  end

  def has_either_address_or_spot
    if spot_id.nil? && full_address.blank?
      errors.add(:base, "Event must have either an Address or a Spot attached.")
    end
  end

  def has_at_least_one_payment_rule
    if payment_per_student.nil? && min_payment_per_session.nil? && max_payment_per_session.nil?
      errors.add(:base, "Must have at least 1 payment rule set.")
    end
  end

end
