# == Schema Information
#
# Table name: athlete_subscriptions
#
#  id              :integer          not null, primary key
#  dependent_id    :integer
#  usages          :integer          default(0)
#  expires_at      :datetime
#  cost_in_pennies :integer          default(0)
#  auto_renew      :boolean          default(TRUE)
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#

class AthleteSubscription < ActiveRecord::Base

  belongs_to :dependent
  after_create :set_default_expiration_date

  scope :active, -> { where("expires_at > ?", Time.zone.now) }
  scope :inactive, -> { where("expires_at <= ?", Time.zone.now) }

  def set_default_expiration_date
    extended_time = if dependent.has_unlimited_access?
      dependent.has_access_until + 1.month
    else
      1.month.from_now
    end
    self.expires_at = extended_time unless expires_at
    self.cost_in_pennies = dependent.user.subscription_cost if cost_in_pennies == 0
    self.save
  end

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

end
