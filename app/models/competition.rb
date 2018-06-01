# == Schema Information
#
# Table name: competitions
#
#  id         :integer          not null, primary key
#  spot_id    :integer
#  name       :string
#  start_time :datetime
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Competition < ApplicationRecord

  belongs_to :spot
  has_many :competitors

  scope :current, -> { where("start_time > ?", DateTime.current) }

end
