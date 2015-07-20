# == Schema Information
#
# Table name: spot_events
#
#  id         :integer          not null, primary key
#  spot_id    :integer
#  event_id   :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class SpotEvent < ActiveRecord::Base
  belongs_to :spot
  belongs_to :event
end
