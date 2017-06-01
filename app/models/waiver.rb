# == Schema Information
#
# Table name: waivers
#
#  id          :integer          not null, primary key
#  athlete_id  :integer
#  signed      :boolean
#  signed_for  :string
#  signed_by   :string
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  expiry_date :datetime
#

class Waiver < ApplicationRecord
  include Defaults

  belongs_to :athlete
  validate :has_matching_name_as_athlete

  default_on_create signed: false
  default_on_create expiry_date: 1.year.from_now - 1.day

  scope :signed, -> { where(signed: true) }
  scope :active, -> { where("expiry_date < ?", Time.zone.now) }
  scope :expires_soon, -> { where("expiry_date IS NULL OR expiry_date >= ?", Time.zone.now - 1.week) }

  def expires_soon?
    return true if expiry_date.nil?
    (Time.zone.now >= (self.expiry_date - 8.days) && self.signed)
  end

  def is_active?
    return false if expiry_date.nil?
    (Time.zone.now < self.expiry_date && self.signed?)
  end

  def has_matching_name_as_athlete
    return unless athlete.present?
    unless athlete.full_name.squish.downcase == self.signed_for.squish.downcase
      errors.add(:signed_for, "Athlete name must match the one listed.")
    end
  end

  def sign!
    self.signed = true
    self.save!
  end

end
