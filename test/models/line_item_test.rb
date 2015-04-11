# == Schema Information
#
# Table name: line_items
#
#  id                   :integer          not null, primary key
#  display_file_name    :string
#  display_content_type :string
#  display_file_size    :integer
#  display_updated_at   :datetime
#  description          :text
#  cost_in_pennies      :integer
#  title                :string
#  category             :string
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  size                 :string
#  hidden               :boolean
#  item_order           :integer
#  credits              :integer          default(0)
#

require 'test_helper'

class LineItemTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
