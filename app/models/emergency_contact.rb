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

  before_save :strip_phone
  validates_presence_of :name, :number

  def strip_phone
    self.number = strip_phone_number(number)
  end

end
