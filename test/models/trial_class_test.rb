# == Schema Information
#
# Table name: trial_classes
#
#  id           :integer          not null, primary key
#  dependent_id :integer
#  used         :boolean          default(FALSE)
#  used_at      :datetime
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#

require 'test_helper'

class TrialClassTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
