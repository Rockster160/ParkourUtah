# == Schema Information
#
# Table name: emergency_contacts
#
#  id      :integer          not null, primary key
#  user_id :integer
#  number  :string
#  name    :string
#

class EmergencyContact < ActiveRecord::Base

  belongs_to :user

  before_save :format_phone

  def format_phone
    self.number = number.gsub(/[^0-9]/, "") if attribute_present?("number")
  end
end
