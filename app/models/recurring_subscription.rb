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

# Add Stripe ID here, and attempt to charge using that customer instead
class RecurringSubscription < ApplicationRecord

  belongs_to :athlete, optional: true
  belongs_to :user

  scope :active, -> { where("expires_at > ?", Time.zone.now) }
  scope :inactive, -> { where("expires_at <= ?", Time.zone.now) }
  scope :unassigned, -> { where(athlete_id: nil) }

  def active?; self.expires_at.to_date > Time.zone.now.to_date; end
  def inactive?; self.expires_at.to_date <= Time.zone.now.to_date; end

  def use!
    return false unless active?
    self.usages += 1
    self.save!
  end

  def cost
    (cost_in_pennies.to_f / 100).round(2)
  end

  def assign_to_athlete(new_athlete)
    return unless new_athlete.present?
    self.athlete_id = new_athlete.id
    set_default_expiration_date
    save
  end

  def set_default_expiration_date
    return unless self.id.nil?
    return if athlete.nil?
    extended_time = if athlete.has_unlimited_access?
      athlete.has_access_until + 1.month
    else
      1.month.from_now
    end
    self.expires_at = extended_time unless expires_at
  end

end