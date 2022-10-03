# == Schema Information
#
# Table name: attendances
#
#  id                     :integer          not null, primary key
#  location               :string
#  sent                   :boolean          default(FALSE)
#  type_of_charge         :string
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  athlete_id             :integer
#  event_id               :integer
#  instructor_id          :integer
#  purchased_plan_item_id :bigint
#

##
# Unused
#
# location
# sent
class Attendance < ApplicationRecord

  attr_accessor :skip_validations, :event_date

  belongs_to :athlete
  belongs_to :instructor, class_name: "User"
  belongs_to :event

  has_many :purchased_plan_items

  validate :one_per_athlete

  # enum type_of_charge: {
  #   credits: 0,
  #   unlimited: 1,
  #   trial: 2
  # }

  def self.type_of_charges
    [
      "Credits",
      "Unlimited Subscription",
      "Trial Class",
      "Plan",
    ]
  end

  def sent!
    self.update(sent: true)
  end

  private

  def one_per_athlete
    unless skip_validations
      matching_attendances = self.class.where(athlete_id: self.athlete_id, event_id: self.event_id)
      if matching_attendances.any? { |a| a.id != self.id }
        errors.add(:base, "Athlete already attended this event.")
      end
    end
  end

end
