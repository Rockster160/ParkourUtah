# == Schema Information
#
# Table name: addresses
#
#  id         :integer          not null, primary key
#  user_id    :integer
#  line1      :string
#  line2      :string
#  city       :string
#  state      :string
#  zip        :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Address < ApplicationRecord

  belongs_to :user

  validates_presence_of :line1, :city, :state, :zip

  def show_address(str)
    str.gsub!("%l1", self.line1)
    str.gsub!("%l2", self.line2)
    str.gsub!("%c", self.city)
    str.gsub!("%s", self.state)
    str.gsub!("%z", self.zip)
    str
  end

end
