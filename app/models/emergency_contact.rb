# == Schema Information
#
# Table name: emergency_contacts
#
#  id      :integer          not null, primary key
#  user_id :integer
#  number  :string
#  name    :string
#

class EmergencyContact < ApplicationRecord
  include ApplicationHelper

  belongs_to :user

  before_save :format_phone
  validates_presence_of :name, :number

  def format_phone
    self.number = number.gsub(/[^0-9]/, "") if attribute_present?("number")
  end

  def show_phone_number
    format_phone_number(self.number)
  end

end
