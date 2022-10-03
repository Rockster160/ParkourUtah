# == Schema Information
#
# Table name: purchased_plan_items
#
#  id              :bigint           not null, primary key
#  auto_renew      :boolean          default(TRUE)
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
  belongs_to :cart, required: true
  belongs_to :plan_item, required: true

  belongs_to :athlete, optional: true

  has_many :attendances

  scope :active, -> { where(expires_at: Time.current...) }
  scope :auto_renew, -> { where(auto_renew: true) }
  scope :unassigned, -> { where(athlete_id: nil) }
end
