# == Schema Information
#
# Table name: line_items
#
#  id                     :integer          not null, primary key
#  bundle_amount                   :integer
#  bundle_cost_in_pennies          :integer
#  bundled_loyalty_cost_in_pennies :integer
#  category               :string
#  color                  :string
#  cost_in_pennies        :integer
#  credits                :integer          default(0)
#  description            :text
#  display_content_type   :string
#  display_file_name      :string
#  display_file_size      :integer
#  display_updated_at     :datetime
#  hidden                 :boolean
#  instructor_ids         :string
#  is_full_image          :boolean          default(FALSE)
#  item_order             :integer
#  location_ids           :string
#  show_text_as_image     :boolean          default(TRUE)
#  size                   :string
#  tags                   :jsonb
#  taxable                :boolean          default(TRUE)
#  time_range_end         :string
#  time_range_start       :string
#  title                  :string
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  plan_item_id           :bigint
#  redemption_item_id     :integer
#

class LineItem < ApplicationRecord

  has_many :redemption_keys
  belongs_to :redemption_item, class_name: "LineItem", optional: true
  belongs_to :plan_item, optional: true

  before_save :assign_item_position_if_nil
  before_destroy :destroy_keys

  def users_who_purchased
    User.joins(carts: [cart_items: [:line_item]]).where(line_items: {id: self.id}).where.not(carts: {purchased_at: nil}).distinct
  end

  def destroy_keys
    CartItem.all.select { |t| t.item.id == self.id }.each { |order| order.destroy }
    self.redemption_keys.each do |key|
      key.destroy
    end
  end

  def colors
    return nil unless color
    my_colors = color.split(',').map(&:squish)
    my_colors.any? ? my_colors : nil
  end

  def sizes
    return nil unless size
    my_sizes = size.split(',').map(&:squish)
    my_sizes.any? ? my_sizes : nil
  end

  def instructors=(ids)
    self.instructor_ids = ids.to_s
  end
  def instructors
    return User.none unless instructor_ids.present?
    User.instructors.where(id: instructor_ids.split(","))
  end

  def locations=(ids)
    self.location_ids = ids.to_s
  end
  def locations
    return Spot.none unless location_ids.present?
    Spot.where(id: location_ids.split(","))
  end

  def possible_time_range
    alotted_times = []
    alotted_times += ["12:00 AM", "12:30 AM"]
    (1..11).each do |t|
      alotted_times += ["#{t}:00 AM", "#{t}:30 AM"]
    end
    alotted_times += ["12:00 PM", "12:30 PM"]
    (1..11).each do |t|
      alotted_times += ["#{t}:00 PM", "#{t}:30 PM"]
    end
    alotted_times
  end

  def time_range
    alotted_times = possible_time_range
    start_idx = alotted_times.index(time_range_start) || 0
    end_idx = alotted_times.index(time_range_end) || alotted_times.length - 1
    alotted_times[start_idx..end_idx]
  end

  def cost
    self.cost_in_pennies
  end

  # Shop-facing "/month" or "/year" suffix. Only plan-backed items recur, and
  # the plan is what decides how often the customer is billed.
  def billing_suffix
    return "" if plan_item.blank?
    plan_item.billing_interval == "year" ? "/year" : "/month"
  end

  def cost_in_dollars=(new_dollar_cost)
    self.cost_in_pennies = new_dollar_cost.to_f * 100
  end
  def cost_in_dollars
    self.cost_in_pennies.to_f / 100
  end

  def bundle_cost=(new_dollar_cost)
    self.bundle_cost_in_pennies = new_dollar_cost.to_f * 100
  end
  def bundle_cost
    return unless bundle_cost_in_pennies.to_i > 0
    self.bundle_cost_in_pennies.to_f / 100
  end

  def loyalty_cost_in_dollars=(new_dollar_cost)
    self.loyalty_cost_in_pennies = new_dollar_cost.to_f * 100
  end
  def loyalty_cost_in_dollars
    return unless loyalty_cost_in_pennies.to_i > 0
    self.loyalty_cost_in_pennies.to_f / 100
  end

  def bundled_loyalty_cost=(new_dollar_cost)
    self.bundled_loyalty_cost_in_pennies = new_dollar_cost.to_f * 100
  end
  def bundled_loyalty_cost
    return unless bundled_loyalty_cost_in_pennies.to_i > 0
    self.bundled_loyalty_cost_in_pennies.to_f / 100
  end

  def loyalty_eligible?(user)
    user.present? && user.created_at < Date.new(2026, 3, 1)
  end

  def loyalty_cost_for(user)
    return unless loyalty_eligible?(user)
    return unless loyalty_cost_in_pennies.to_i > 0
    loyalty_cost_in_pennies
  end

  def bundled_loyalty_cost_for(user, amount)
    return unless loyalty_eligible?(user)
    return unless bundled_loyalty_cost_in_pennies.to_i > 0
    return unless bundle_amount.to_i > 0 && amount >= bundle_amount
    bundled_loyalty_cost_in_pennies
  end

  def exceeds_bundle?(amount)
    return false unless bundle_amount.to_i > 0 && bundle_cost_in_pennies.to_i > 0
    amount >= bundle_amount
  end

  def cost_for(amount, user=nil)
    priced_options_for(amount, user).min_by { |o| o[:total] }[:total].round
  end

  # Returns which discount produced the winning `cost_for` price, so the cart
  # can explain why the total is what it is. nil means no discount applied.
  def discount_label_for(amount, user=nil)
    winner = priced_options_for(amount, user).min_by { |o| o[:total] }
    winner[:label]
  end

  def effective_unit_price_for(amount, user=nil)
    # Zero is reachable (CartItem#verify_amount_is_not_nil coerces a nil amount to
    # it), and 0 / 0.0 is NaN, which blows up on .round. There is no per-unit
    # bundle price to work out at that point, so fall back to the plain unit price.
    return unit_price_for(user) if amount.to_i <= 0

    (cost_for(amount, user) / amount.to_f).round
  end

  # Per-unit price with only user-specific discounts applied (loyalty, plan).
  # Bundle/family pricing is intentionally excluded so the cart can show it
  # separately as a savings line.
  def unit_price_for(user=nil)
    cost_for(1, user)
  end

  def priced_options_for(amount, user=nil)
    options = [{ total: cost.to_f * amount, label: nil }]

    discount_data = discounted_cost_data(user)
    options << { total: discount_data[:cost] * amount, label: "Plan discount" } if discount_data
    options << { total: bundle_cost_in_pennies * amount, label: "Family discount" } if exceeds_bundle?(amount)
    loyalty = loyalty_cost_for(user)
    options << { total: loyalty * amount, label: "Loyalty discount" } if loyalty
    bundled_loyalty = bundled_loyalty_cost_for(user, amount)
    options << { total: bundled_loyalty * amount, label: "Family + Loyalty discount" } if bundled_loyalty

    options
  end

  def tax_for(amount, user=nil)
    return 0 unless taxable?
    tax_multiplier = 0.0825
    (cost_for(amount, user) * tax_multiplier).round
  end

  def discounted_cost_in_dollars(user)
    candidates = []

    data = discounted_cost_data(user)
    candidates.push(data[:cost]) if data

    loyalty = loyalty_cost_for(user)
    candidates.push(loyalty) if loyalty

    best = candidates.min
    return unless best.present?
    return if best >= cost_in_pennies

    (best / 100.to_f)
  end

  def discounted_cost_data(user)
    return unless user.present?
    return unless tags.present?

    cip = cost_in_pennies
    plans = user.purchased_plan_items.active.assigned

    potential_discounts = plans.each_with_object([]) do |plan, arr|
      # discount_items: [{"tags"=>["classes"], "discount"=>"50%"}]
      plan.discount_items&.each do |item|
        matching_tags = item["tags"] & tags
        next unless matching_tags.any?

        cost = cip
        clean = item["discount"][/[\d.]+/].to_f
        if item["discount"].include?("%")
          cost = cip * (clean / 100.to_f)
        elsif item["discount"].include?("$")
          cost = cip - (clean * 100)
        end

        arr.push(
          plan_id: plan.id,
          discount: item["discount"],
          tag: matching_tags.first,
          cost: cost.clamp(0..),
        )
      end
    end

    # Best discount
    potential_discounts.sort_by { |discount| discount[:cost] }.first
  end

  def assign_item_position_if_nil
    unless self.item_order
      self.item_order = (LineItem.all.map { |l| l.item_order }.compact.sort.last + 1)
      self.save!
    end
  end

  def tags=(new_tag_str)
    super(new_tag_str.split(",").map { |tag| tag.downcase.squish })
  end

end
