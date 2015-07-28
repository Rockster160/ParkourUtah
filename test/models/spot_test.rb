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

require 'test_helper'

class SpotTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
