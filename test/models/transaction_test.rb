# == Schema Information
#
# Table name: transactions
#
#  id             :integer          not null, primary key
#  cart_id        :integer
#  item_id        :integer
#  amount         :integer          default(1)
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  redeemed_token :string
#

require 'test_helper'

class TransactionTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
