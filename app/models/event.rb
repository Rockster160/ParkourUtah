# == Schema Information
#
# Table name: events
#
#  id                :integer          not null, primary key
#  date              :datetime
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  event_schedule_id :integer
#  is_cancelled      :boolean          default(FALSE)
#

class Event < ActiveRecord::Base

  belongs_to :event_schedule
  has_many :attendances, dependent: :destroy

  after_initialize :set_default_values
  before_save :format_fields
  before_save :add_hash_to_colors

  scope :in_the_future, -> { where("date > ?", Time.zone.now) }
  scope :today, -> { by_date(Time.zone.now) }
  scope :by_date, -> (date) { in_date_range(date, date) }
  scope :in_date_range, -> (first_day, last_day) {
    time_zone = Time.zone
    first_date = time_zone.local(first_day.year, first_day.month, first_day.day).beginning_of_day
    last_date = time_zone.local(last_day.year, last_day.month, last_day.day).end_of_day
    where(date: first_date..last_date)
  }

  delegate :instructor,      to: :event_schedule, allow_nil: true
  delegate :spot,            to: :event_schedule, allow_nil: true
  delegate :hour_of_day,     to: :event_schedule, allow_nil: true
  delegate :minute_of_day,   to: :event_schedule, allow_nil: true
  delegate :day_of_week,     to: :event_schedule, allow_nil: true
  delegate :cost_in_pennies, to: :event_schedule, allow_nil: true
  delegate :title,           to: :event_schedule, allow_nil: true
  delegate :description,     to: :event_schedule, allow_nil: true
  delegate :full_address,    to: :event_schedule, allow_nil: true
  delegate :city,            to: :event_schedule, allow_nil: true
  delegate :color,           to: :event_schedule, allow_nil: true
  delegate :time_of_day,     to: :event_schedule, allow_nil: true
  delegate :host_name,       to: :event_schedule, allow_nil: true

  def css_style
    "background-color: #{color.presence || '#FFF'} !important; color: #{color_contrast} !important; background-image: none !important;"
  end

  def add_hash_to_colors
    color.prepend('#') if color.present? && (color.length == 3 || color.length == 6)
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

  def self.cities
    pluck(:city).uniq
  end

  def self.random_color
    "##{6.times.map { rand(16).to_s(16) }.join('')}"
  end

  def self.color_of(title)
    classes = where(title: title)
    if classes.any?
      color = classes.last.color
      return color.presence || random_color
    else
      random_color
    end
  end

  def self.future_classes_in(city)
    where(city: city).where("date >= ?", Time.zone.now)
  end

  def self.sort_by_token
    self.where("date > ?", Time.zone.now).group_by do |all_events|
      all_events.token
    end.map do |keys, values|
      values.sort_by {|v| v.id}.first
    end.sort_by { |event| event.city }
  end

  def self.by_token(token)
    where(token: token)
  end

  def self.next_class_by_token(token)
    where('date > ?', Time.zone.now).where(token: token).order(date: :asc).first
  end

  def self.names_with_tokens
    tokens = Event.order(:date).pluck(:token).uniq
    tokens.map do |token|
      event = next_class_by_token(token)
      next unless event.present?
      ["#{event.date.strftime('%A %l:%M')} #{event.title}", event.id]
    end.compact
  end

  def cancel!
    update(cancelled_text: true)
  end

  def uncancel!
    update(cancelled_text: false)
  end

  def cancelled?
    cancelled_text
  end

  def cost_in_dollars
    self.cost.to_f / 100
  end

  private

  def random_color; self.class.random_color; end

  def format_fields
    format_city_name
  end

  def format_city_name
    self.city = self.city.squish.split.map(&:capitalize).join(' ')
  end

  def set_default_values
    self.color ||= random_color
  end

end
