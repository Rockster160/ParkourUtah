# == Schema Information
#
# Table name: venmos
#
#  id            :integer          not null, primary key
#  access_token  :string
#  refresh_token :string
#  expires_at    :datetime
#  username      :string
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#

require 'test_helper'

class VenmoTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end