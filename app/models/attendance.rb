# == Schema Information
#
# Table name: attendances
#
#  id             :integer          not null, primary key
#  dependent_id   :integer
#  user_id        :integer
#  event_id       :integer
#  location       :string
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  type_of_charge :string
#  sent           :boolean          default(FALSE)
#

class Attendance < ActiveRecord::Base

  belongs_to :dependent
  belongs_to :instructor
  belongs_to :event

  def athlete
    Dependent.find_by_athlete_id(self.dependent_id)
  end
  
end
