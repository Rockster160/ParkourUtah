# == Schema Information
#
# Table name: line_items
#
#  id                     :integer          not null, primary key
#  bundle_amount          :integer
#  bundle_cost_in_pennies :integer
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
#  is_subscription        :boolean          default(FALSE)
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

  # has_attached_file :display,
  #   styles: { :medium => "300x300>", :thumb => "100x100#" },
  #   :default_url => "http://parkourutah.com/images/missing.png",
  #   :storage => :s3,
  #   :bucket => ENV['PKUT_S3_BUCKET_NAME'],
  #   :convert_options => { :all => '-background white -flatten +matte' }
  # validates_attachment_content_type :display, :content_type => /\Aimage\/.*\Z/

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

  def exceeds_bundle?(amount)
    return false unless bundle_amount.to_i > 0 && bundle_cost_in_pennies.to_i > 0
    amount >= bundle_amount
  end

  def cost_for(amount, user=nil)
    discount_data = discounted_cost_data(user)
    possible_prices = [cost.to_f * amount]

    possible_prices.push(discount_data[:cost] * amount) if discount_data
    possible_prices.push(bundle_cost_in_pennies * amount) if exceeds_bundle?(amount)

    possible_prices.sort.first.round
  end

  def tax_for(amount, user=nil)
    return 0 unless taxable?
    tax_multiplier = 0.0825
    (cost_for(amount, user) * tax_multiplier).round
  end

  def discounted_cost_in_dollars(user)
    data = discounted_cost_data(user)
    return unless data.present?

    (data[:cost] / 100.to_f)
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
        clean = item["discount"][/(\d|\.)*/].to_f
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
