# == Schema Information
#
# Table name: plan_items
#
#  id               :integer          not null, primary key
#  name             :text
#  free_items       :jsonb
#  discount_items   :jsonb
#  billing_interval :string           default("month")
#  covers_family    :boolean          default(FALSE), not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#

class PlanItem < ApplicationRecord
  BILLING_INTERVALS = %w[month year].freeze

  has_many :purchased_plan_items
  has_one :line_item

  validates :billing_interval, inclusion: { in: BILLING_INTERVALS }

  # A family plan is bought once at a flat price and covers every athlete on
  # the account, rather than only the one the purchase was assigned to.
  scope :covering_family, -> { where(covers_family: true) }

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
      item[:discount] = item[:discount].squish.then { |discount|
        if discount.include?("$")
          "$#{discount[/[\d.]+/]}"
        elsif discount.include?("%")
          "#{discount[/[\d.]+/]}%"
        else
          discount
        end
      }
      item
    }.compact

    super(fixed_json)
  end
end
