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
    self.line1.length > 0
  end

end
