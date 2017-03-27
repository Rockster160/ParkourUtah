# == Schema Information
#
# Table name: announcements
#
#  id           :integer          not null, primary key
#  admin_id     :integer
#  expires_at   :datetime
#  body         :text
#  delivered_at :datetime
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#

class Announcement < ApplicationRecord
  belongs_to :admin, class_name: "User"
  has_many :announcement_views

  validates_presence_of :body

  scope :not_expired, -> { where("announcements.expires_at > ?", Time.zone.now) }
  scope :delivered, -> { where.not(delivered_at: nil) }
  scope :not_delivered, -> { where(delivered_at: nil) }

  def view_count
    announcement_views.count
  end

  def deliver
    update(delivered_at: Time.zone.now)
  end

  def delivered?
    !delivered_at.nil?
  end

  def display
    display_html = body
    display_html = display_html.gsub("\r", '')
    display_html = display_html.gsub("\n", "<br>")
    display_html = display_html.gsub(/\*(.|\n)*?\*/) { |bold_txt| "<b>#{bold_txt[1..-2]}</b>" }
    display_html = display_html.gsub(/\~(.|\n)*?\~/) { |red_txt| "<span class=\"announcement-red\">#{red_txt[1..-2]}</span>" }
    display_html = display_html.gsub(/\+(.|\n)*?\+/) { |large_txt| "<span class=\"announcement-large\">#{large_txt[1..-2]}</span>" }
    display_html = display_html.gsub(/\((.|\n)*?\)\[(.|\n)*?\]/) { |link_txt| msg, url = link_txt[1..-2].split(")["); "<a href=\"#{url}\" class=\"announcement-link\" target=\"_blank\">#{msg}</a>" }
    display_html.html_safe
  end

  def expires_at_date=(new_date)
    current_date = (self.expires_at || Time.zone.now).to_datetime
    begin
      parsed_date = Time.zone.parse(new_date).to_datetime
      self.expires_at = Time.zone.local(parsed_date.year, parsed_date.month, parsed_date.day, current_date.hour, current_date.minute)
    rescue => e
      errors.add(:expires_at, "must have a valid Date.")
    end
  end
  def expires_at_date
    current_date = (self.expires_at || Time.zone.now).to_datetime
    current_date.strftime("%b %d, %Y")
  end

  def expires_at_time=(new_time)
    current_date = (self.expires_at || Time.zone.now).to_datetime
    begin
      parsed_date = Time.zone.parse(new_time).to_datetime
      self.expires_at = Time.zone.local(current_date.year, current_date.month, current_date.day, parsed_date.hour, parsed_date.minute)
    rescue => e
      errors.add(:expires_at, "must have a valid Time.")
    end
  end
  def expires_at_time
    current_date = (self.expires_at || Time.zone.now).to_datetime
    current_date.strftime("%-l:%M %p")
  end


end
