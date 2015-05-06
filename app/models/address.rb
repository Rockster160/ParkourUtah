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

class Address < ActiveRecord::Base

  belongs_to :user

  before_create :make_empty_fields

  def make_empty_fields
    self.line1 ||= ""
    self.line2 ||= ""
    self.city ||= ""
    self.state ||= ""
    self.zip ||= ""
  end

  def is_valid?
    self.line1.length > 0 &&
    self.city.length > 0 &&
    self.state.length > 0 &&
    self.zip.length > 0
  end

  def show_address(str)
    str.gsub!("%l1", self.line1)
    str.gsub!("%l2", self.line2)
    str.gsub!("%c", self.city)
    str.gsub!("%s", self.state)
    str.gsub!("%z", self.zip)
    str
  end

end
