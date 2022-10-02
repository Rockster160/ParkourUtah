# == Schema Information
#
# Table name: purchased_plan_items
#
#  id             :bigint           not null, primary key
#  discount_items :jsonb
#  free_items     :jsonb
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  athlete_id     :bigint
#  cart_id        :bigint
#  plan_item_id   :bigint
#  user_id        :bigint
#
class PurchasedPlanItem < ApplicationRecord
  belongs_to :user
  belongs_to :athlete
  belongs_to :cart
  belongs_to :plan_item
end
