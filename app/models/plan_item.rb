# == Schema Information
#
# Table name: plan_items
#
#  id             :bigint           not null, primary key
#  discount_items :jsonb
#  free_items     :jsonb
#  name           :text
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#
class PlanItem < ApplicationRecord
  has_many :purchased_plan_items
end
