# == Schema Information
#
# Table name: redemption_keys
#
#  id           :integer          not null, primary key
#  key          :string
#  redemption   :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  redeemed     :boolean          default(FALSE)
#  line_item_id :integer
#

require 'test_helper'

class RedemptionKeyTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
