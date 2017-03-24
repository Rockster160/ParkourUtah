# == Schema Information
#
# Table name: events
#
#  id                :integer          not null, primary key
#  date              :datetime
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  event_schedule_id :integer
#  original_date     :datetime
#  is_cancelled      :boolean          default(FALSE)
#

class Event < ApplicationRecord
  include Defaults

  belongs_to :event_schedule
  has_many :attendances, dependent: :destroy

  validates_presence_of :date

  after_initialize :set_original_date

  scope :in_the_future, -> { where("date > ?", Time.zone.now) }
  scope :today, -> { by_date(Time.zone.now) }
  scope :by_date, -> (date) { in_date_range(date, date) }
  scope :in_date_range, -> (first_day, last_day) {
    time_zone = Time.zone
    first_date = time_zone.local(first_day.year, first_day.month, first_day.day).beginning_of_day
    last_date = time_zone.local(last_day.year, last_day.month, last_day.day).end_of_day
    where(date: first_date..last_date)
  }

  delegate :instructor,                 to: :event_schedule, allow_nil: true
  delegate :spot,                       to: :event_schedule, allow_nil: true
  delegate :hour_of_day,                to: :event_schedule, allow_nil: true
  delegate :minute_of_day,              to: :event_schedule, allow_nil: true
  delegate :day_of_week,                to: :event_schedule, allow_nil: true
  delegate :cost_in_pennies,            to: :event_schedule, allow_nil: true
  delegate :title,                      to: :event_schedule, allow_nil: true
  delegate :description,                to: :event_schedule, allow_nil: true
  delegate :full_address,               to: :event_schedule, allow_nil: true
  delegate :city,                       to: :event_schedule, allow_nil: true
  delegate :color,                      to: :event_schedule, allow_nil: true
  delegate :time_of_day,                to: :event_schedule, allow_nil: true
  delegate :host_name,                  to: :event_schedule, allow_nil: true
  delegate :subscribed_users,           to: :event_schedule, allow_nil: true
  delegate :cost_in_dollars,            to: :event_schedule, allow_nil: true
  delegate :payment_per_student,        to: :event_schedule, allow_nil: true
  delegate :min_payment_per_session,    to: :event_schedule, allow_nil: true
  delegate :max_payment_per_session,    to: :event_schedule, allow_nil: true
  delegate :accepts_unlimited_classes,  to: :event_schedule
  delegate :accepts_unlimited_classes?, to: :event_schedule
  delegate :accepts_trial_classes,      to: :event_schedule
  delegate :accepts_trial_classes?,     to: :event_schedule

  def update_date(new_date_params)
    new_date = Time.zone.parse(new_date_params[:str_date]) rescue nil
    return if new_date.nil?
    new_time_str = new_date_params[:time_of_day]
    return if new_time_str.split(":")[0].to_i <= 12 && (new_time_str =~ /(a|p)m/i).nil?
    time = Time.zone.parse(new_time_str) rescue nil
    new_datetime = Time.zone.local(new_date.year, new_date.month, new_date.day, time.try(:hour), time.try(:min)) rescue nil
    return if new_datetime.nil?
    self.date = new_datetime
    self.save
  end

  def str_date; date.strftime('%b %d, %Y'); end
  def original_time_of_day; event_schedule.time_of_day; end
  def time_of_day; date.strftime("%-l:%M %p"); end

  def css_style
    "background-color: #{color.presence || '#FFF'} !important; color: #{color_contrast} !important; background-image: none !important;"
  end

  def color_contrast(contrasted_color=color)
    contrasted_color = contrasted_color.presence || '#FFF'
    black, white = '#000', '#FFF'
    return white unless contrasted_color.present?
    color = contrasted_color.gsub('#', '')
    return white unless color.length == 6 || color.length == 3
    r_255, g_255, b_255 = color.chars.in_groups(3).map { |hex_val| (hex_val.many? ? hex_val : hex_val*2).join.to_i(16) }
    r_lum, g_lum, b_lum = r_255 * 299, g_255 * 587, b_255 * 114
    luminescence = ((r_lum + g_lum + b_lum) / 1000)
    return luminescence > 150 ? black : white
  end

  def cancel!
    update(is_cancelled: true)
  end

  def uncancel!
    update(is_cancelled: false)
  end

  def cancelled?
    is_cancelled?
  end

  def set_original_date
    return unless original_date.nil?
    self.original_date = self.date
  end

end
