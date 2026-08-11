# == Schema Information
#
# Table name: purchased_plan_items
#
#  id              :integer          not null, primary key
#  user_id         :integer
#  athlete_id      :integer
#  cart_id         :integer
#  plan_item_id    :integer
#  cost_in_pennies :integer
#  expires_at      :datetime
#  auto_renew      :boolean          default(TRUE)
#  stripe_id       :text
#  card_declined   :text
#  free_items      :jsonb
#  discount_items  :jsonb
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
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

  # Plans bill on their own cadence. A yearly pass must not come up for renewal
  # a month after it was assigned, or the customer gets charged the full annual
  # price twelve times a year.
  def renewal_length
    plan_item&.billing_interval == "year" ? 1.year : 1.month
  end

  def next_expires_at(from = Time.current)
    from + renewal_length
  end

  def assign_to_athlete(new_athlete)
    return unless new_athlete.present?

    self.athlete_id = new_athlete.id
    update(expires_at: next_expires_at)
  end

  # free_items: [{"tags"=>["classes"], "count"=>2, "interval"=>"week"}],
  # discount_items: [{"tags"=>["classes"], "discount"=>"50%"}]
end
