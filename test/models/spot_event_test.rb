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

require 'test_helper'

class SpotEventTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
