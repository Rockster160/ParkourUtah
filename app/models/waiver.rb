# == Schema Information
#
# Table name: waivers
#
#  id           :integer          not null, primary key
#  dependent_id :integer
#  signed       :boolean
#  signed_for   :string
#  signed_by    :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#

class Waiver < ActiveRecord::Base

  belongs_to :dependent
  validate :has_matching_name_as_athlete
  after_create :signed_false

  def exp_date
    (self.created_at + 1.year - 1.day)
  end

  def expires_soon?
    (Date.today >= (self.exp_date.to_date - 1.week) && self.signed)
  end

  def is_active?
    (Date.today < self.exp_date.to_date && self.signed?)
  end

  def has_matching_name_as_athlete
    unless Dependent.find(self.dependent_id).full_name.squish.downcase == self.signed_for.squish.downcase
      errors.add(:signed_for, "Athlete name must match the one listed.")
    end
  end

  def signed_false
    self.signed = false
  end

end
