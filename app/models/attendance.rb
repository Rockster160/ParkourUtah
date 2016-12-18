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

# TODO Rename associations to be better
class Attendance < ActiveRecord::Base

  attr_accessor :skip_validations

  belongs_to :dependent
  belongs_to :user # Instructor
  belongs_to :event

  validate :one_per_athlete

  def athlete; dependent; end
  def instructor; user; end

  def sent!
    self.update(sent: true)
  end

  private

  def one_per_athlete
    unless skip_validations
      matching_attendances = self.class.where(dependent_id: self.dependent_id, event_id: self.event_id)
      if matching_attendances.any? { |a| a.id != self.id }
        errors.add(:base, "Athlete already attended this event.")
      end
    end
  end

end
