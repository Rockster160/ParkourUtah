# == Schema Information
#
# Table name: recurring_subscriptions
#
#  id              :integer          not null, primary key
#  athlete_id      :integer
#  usages          :integer          default(0)
#  expires_at      :datetime
#  cost_in_pennies :integer          default(0)
#  auto_renew      :boolean          default(TRUE)
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  stripe_id       :string
#  user_id         :integer
#

class RecurringSubscription < ApplicationRecord

  belongs_to :athlete, optional: true
  belongs_to :user

  scope :auto_renew, -> { where(auto_renew: true) }
  scope :assigned, -> { where.not(athlete_id: nil) }
  scope :unassigned, -> { where(athlete_id: nil) }
  scope :active, -> { assigned.where("expires_at > ?", Time.zone.now) }
  scope :inactive, -> { assigned.where("expires_at <= ?", Time.zone.now) }

  validates_presence_of :expires_at, if: ->{ athlete_id.present? }

  before_save :set_default_expiration_date

  def active?; self.expires_at.to_date > Time.zone.now.to_date; end
  def inactive?; self.expires_at.to_date <= Time.zone.now.to_date; end

  def use!
    return false unless active?
    self.usages += 1
    self.save!
  end

  def cost
    (cost_in_pennies / 100.to_f).round(2)
  end

  def assign_to_athlete(new_athlete)
    return unless new_athlete.present?
    self.athlete_id = new_athlete.id
    set_default_expiration_date
    save
  end

  def set_default_expiration_date
    return if athlete.nil?
    return if expires_at.present?
    extended_time = if athlete.has_unlimited_access?
      athlete.has_access_until + 1.month
    else
      1.month.from_now
    end
    self.expires_at = extended_time
    self.save
  end

end
