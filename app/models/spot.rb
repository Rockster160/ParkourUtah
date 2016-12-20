# == Schema Information
#
# Table name: spots
#
#  id          :integer          not null, primary key
#  title       :string
#  description :text
#  lon         :string
#  lat         :string
#  approved    :boolean          default(FALSE)
#  event_id    :integer
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  location    :string
#

class Spot < ActiveRecord::Base
  
  has_many :event_schedules
  has_many :images
  has_many :ratings

  validates :lon, :lat, presence: true

  def rating
    return 0 unless ratings.length > 0
    ratings.collect(&:rated).sum.to_f/ratings.length
  end

  def rated
    return ratings.length
  end

  def verify_coords
  end

  def self.spot_titles
    all.map { |s| s.title }
  end

end
