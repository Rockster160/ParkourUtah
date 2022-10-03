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
  has_one :line_item

  def free_items=(new_json)
    fixed_json = new_json.map { |item|
      item = item.with_indifferent_access
      next if item[:tags].blank?

      item[:tags] = item[:tags].split(",").map { |tag| tag.squish.downcase.presence }.compact
      item[:count] = item[:count].to_i
      item
    }.compact

    super(fixed_json)
  end

  def discount_items=(new_json)
    fixed_json = new_json.map { |item|
      item = item.with_indifferent_access
      next if item[:tags].blank?
      next if item[:discount].blank?

      item[:tags] = item[:tags].split(",").map { |tag| tag.squish.downcase.presence }.compact
      item[:discount] = item[:discount].squish.tap { |discount|
        if discount.include?("$")
          "$#{discount[/(\d\.)+/]}"
        elsif discount.include?("%")
          "#{discount[/(\d\.)+/]}%"
        end
      }
      item
    }.compact

    super(fixed_json)
  end
end
