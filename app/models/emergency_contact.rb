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

  def show_phone_number
    format_phone_number_to_display(self.number)
  end

  private

  def format_phone_number_to_display(number)
    return "" unless number && number.length == 10
    "(#{number[0..2]}) #{number[3..5]}-#{number[6..9]}"
  end

end
