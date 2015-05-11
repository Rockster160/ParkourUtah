# == Schema Information
#
# Table name: unlimited_subscriptions
#
#  id         :integer          not null, primary key
#  usages     :integer          default(0)
#  expires_at :datetime
#  user_id    :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

require 'test_helper'

class UnlimitedSubscriptionTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
