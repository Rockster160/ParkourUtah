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
  scope :family, -> { where(plan_item_id: PlanItem.covering_family.select(:id)) }

  # Renewal candidates. A normal plan does nothing until it is assigned to an
  # athlete, but a family pass covers the whole account and is never assigned,
  # so filtering on `assigned` alone would let family passes run forever
  # without ever billing again.
  scope :renewable, -> { assigned.or(family) }

  # A family pass covers every athlete on the account, so there is nobody to
  # assign it to and nothing to wait for — it starts the moment it is bought.
  # Every other plan has its clock started by `assign_to_athlete`.
  after_create :start_family_coverage


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

  def family?
    plan_item&.covers_family? || false
  end

  # A family pass needs no athlete, so the "assign me" prompts and the
  # unassigned styling should leave it alone.
  def awaiting_assignment?
    athlete_id.blank? && !family?
  end

  def assign_to_athlete(new_athlete)
    return unless new_athlete.present?

    self.athlete_id = new_athlete.id
    update(expires_at: next_expires_at)
  end

  # free_items: [{"tags"=>["classes"], "count"=>2, "interval"=>"week"}],
  # discount_items: [{"tags"=>["classes"], "discount"=>"50%"}]

  private

  # Renewals and the billing-realignment service set their own expiry; only a
  # fresh purchase arrives without one.
  def start_family_coverage
    return unless expires_at.nil?
    return unless family?

    update_column(:expires_at, next_expires_at(created_at || Time.current))
  end
end
