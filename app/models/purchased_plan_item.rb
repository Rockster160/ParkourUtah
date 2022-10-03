# == Schema Information
#
# Table name: purchased_plan_items
#
#  id              :bigint           not null, primary key
#  auto_renew      :boolean          default(TRUE)
#  card_declined   :text
#  cost_in_pennies :integer
#  discount_items  :jsonb
#  expires_at      :datetime
#  free_items      :jsonb
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  athlete_id      :bigint
#  cart_id         :bigint
#  plan_item_id    :bigint
#  stripe_id       :text
#  user_id         :bigint
#

class PurchasedPlanItem < ApplicationRecord
  belongs_to :user, required: true
  belongs_to :plan_item, required: true

  belongs_to :cart, optional: true # Follow up subscriptions have an empty cart
  belongs_to :athlete, optional: true

  has_many :attendances

  scope :active, -> { where(expires_at: [nil, Time.current...]) }
  scope :inactive, -> { where(expires_at: ...1.second.ago) }
  scope :auto_renew, -> { where(auto_renew: true) }
  scope :assigned, -> { where.not(athlete_id: nil) }
  scope :unassigned, -> { where(athlete_id: nil) }
  scope :available, -> { where(card_declined: [nil, ""]) }

  def cost
    (cost_in_pennies / 100.to_f).round(2)
  end

  def assign_to_athlete(new_athlete)
    return unless new_athlete.present?

    self.athlete_id = new_athlete.id
    update(expires_at: 1.month.from_now)
  end
end
