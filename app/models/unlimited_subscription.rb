 # == Schema Information
#
# Table name: unlimited_subscriptions
#
#  id         :integer          not null, primary key
#  usages     :integer          default(0)
#  expires_at :datetime
#  user_id    :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class UnlimitedSubscription < ActiveRecord::Base

  belongs_to :user
  after_create :set_default_expiration_date

  def set_default_expiration_date
    self.update(expires_at: 1.month.from_now)
  end

  def active?
    self.expires_at > DateTime.current.to_date
  end

  def use!
    return false unless active?
    self.usages += 1
    self.save!
    "Unlimited Subscription - User ID: #{self.user_id}"
  end

end
