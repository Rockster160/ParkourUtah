# == Schema Information
#
# Table name: events
#
#  id                    :integer          not null, primary key
#  date                  :datetime
#  token                 :integer
#  title                 :string
#  host                  :string
#  cost                  :float
#  description           :text
#  city                  :string
#  address               :string
#  location_instructions :string
#  class_name            :string
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  zip                   :string
#  state                 :string           default("Utah")
#  color                 :string
#  cancelled_text        :boolean          default(FALSE)
#

# Unused
# city address location_instructions zip state

class Event < ActiveRecord::Base

  # "#{address}"
  # "#{city}, #{state.abbreviate_state} #{zip}"

  has_many :attendances, dependent: :destroy
  has_many :spot_events, dependent: :destroy
  accepts_nested_attributes_for :spot_events, allow_destroy: true
  has_many :subscriptions, dependent: :destroy

  after_initialize :set_default_values
  before_save :format_fields
  before_save :add_hash_to_colors

  scope :today, -> { by_date(DateTime.current) }
  scope :by_date, -> (date) { in_date_range(date, date) }
  scope :in_date_range, -> (first_day, last_day) {
    time_zone = Time.zone
    first_date = time_zone.local(first_day.year, first_day.month, first_day.day).beginning_of_day
    last_date = time_zone.local(last_day.year, last_day.month, last_day.day).end_of_day
    where(date: first_date..last_date)
  }

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

  def recurring?
    Event.by_token(token).count > 1
  end

  def self.color_of(class_name)
    classes = where(class_name: class_name)
    if classes.any?
      color = classes.last.color
      return color.presence || random_color
    else
      random_color
    end
  end

  def self.future_classes_in(city)
    where(city: city).where("date >= ?", DateTime.current)
  end

  def self.sort_by_token
    self.where("date > ?", DateTime.current).group_by do |all_events|
      all_events.token
    end.map do |keys, values|
      values.sort_by {|v| v.id}.first
    end.sort_by { |event| event.city }
  end

  def self.by_token(token)
    where(token: token)
  end

  def self.next_class_by_token(token)
    where('date > ?', DateTime.current).where(token: token).order(date: :asc).first
  end

  def self.names_with_tokens
    tokens = Event.order(:date).pluck(:token).uniq
    tokens.map do |token|
      event = next_class_by_token(token)
      next unless event.present?
      ["#{event.date.strftime('%A %l:%M')} #{event.class_name}", event.id]
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

  def subscribed_users
    subscriptions.map(&:user)
  end

  def cost_in_dollars
    self.cost.to_f / 100
  end

  def abbreviate_state
    state = self.state.squish.split.map(&:capitalize).join(' ')
    case state
      when "Alabama" then "AL"
      when "Alaska" then "AK"
      when "Arizona" then "AZ"
      when "Arkansas" then "AR"
      when "California" then "CA"
      when "Colorado" then "CO"
      when "Connecticut" then "CT"
      when "Delaware" then "DE"
      when "Florida" then "FL"
      when "Georgia" then "GA"
      when "Hawaii" then "HI"
      when "Idaho" then "ID"
      when "Illinois" then "IL"
      when "Indiana" then "IN"
      when "Iowa" then "IA"
      when "Kansas" then "KS"
      when "Kentucky" then "KY"
      when "Louisiana" then "LA"
      when "Maine" then "ME"
      when "Maryland" then "MD"
      when "Massachusetts" then "MA"
      when "Michigan" then "MI"
      when "Minnesota" then "MN"
      when "Mississippi" then "MS"
      when "Missouri" then "MO"
      when "Montana" then "MT"
      when "Nebraska" then "NE"
      when "Nevada" then "NV"
      when "New Hampshire" then "NH"
      when "New Jersey" then "NJ"
      when "New Mexico" then "NM"
      when "New York" then "NY"
      when "North Carolina" then "NC"
      when "North Dakota" then "ND"
      when "Ohio" then "OH"
      when "Oklahoma" then "OK"
      when "Oregon" then "OR"
      when "Pennsylvania" then "PA"
      when "Rhode Island" then "RI"
      when "South Carolina" then "SC"
      when "South Dakota" then "SD"
      when "Tennessee" then "TN"
      when "Texas" then "TX"
      when "Utah" then "UT"
      when "Vermont" then "VT"
      when "Virginia" then "VA"
      when "Washington" then "WA"
      when "West Virginia" then "WV"
      when "Wisconsin" then "WI"
      when "Wyoming" then "WY"
      else state
    end
  end

  private

  def self.random_color
    "##{3.times.map { rand(256).to_s(16) }.join('')}"
  end
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
