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

# TODO Remove me in a later migration
class SpotEvent < ActiveRecord::Base
end
