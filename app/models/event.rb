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
#  color                 :integer
#

class Event < ActiveRecord::Base

  # "#{address}"
  # "#{city}, #{state.abbreviate_state} #{zip}"

  has_many :attendances
  has_many :subscriptions, dependent: :destroy

  before_save :format_fields
  after_create :set_color

  enum color: [
    :red,
    :orange,
    :yellow,
    :yellowgreen,
    :green,
    :cyan,
    :babyblue,
    :pink,
    :lightpurple,
    :azure,
    :blue,
    :violet,
    :magenta,
    :rose
  ]

  # Event.all.to_a.group_by { |event| event.city }.keys.each_with_index { |city, pos| Event.set_city_color(city, Event.colors.keys[pos]) }


  def self.color_of(city)
    cities = where(city: city)
    binding.pry if city == nil
    if cities.any?
      color = cities.first.color
      (color.nil? || color.empty?) ? self.set_city_color(city) : color
    else
      ""
    end
  end

  def self.by_token
    self.where("date > ?", Time.now.to_date).group_by do |all_events|
      all_events.token
    end.map do |keys, values|
      values.sort_by {|v| v.id}.first
    end.sort_by { |event| event.city }
  end

  def cost_in_dollars
    self.cost.to_f / 100
  end

  def set_color
    self.color = Event.color_of(self.city)
    self.save
  end

  def self.set_city_color(city, color="rand")
    new_color = color == "rand" ? self.colors.keys.sample : color
    where(city: city).each do |event|
      event.update(color: new_color)
    end
    new_color
  end

  def host_by_id
    User.find(host)
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

  def format_fields
    format_city_name
    # self.color = Event.color_of(self.city)
  end

  def format_city_name
    self.city = self.city.squish.split.map(&:capitalize).join(' ')
  end

end
