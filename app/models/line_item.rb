# == Schema Information
#
# Table name: line_items
#
#  id                   :integer          not null, primary key
#  display_file_name    :string
#  display_content_type :string
#  display_file_size    :integer
#  display_updated_at   :datetime
#  description          :text
#  cost_in_pennies      :integer
#  title                :string
#  category             :string
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  size                 :string
#  hidden               :boolean
#  item_order           :integer
#  credits              :integer          default(0)
#  is_subscription      :boolean          default(FALSE)
#  taxable              :boolean          default(TRUE)
#  color                :string
#  is_full_image        :boolean          default(FALSE)
#  redemption_item_id   :integer
#  show_text_as_image   :boolean          default(TRUE)
#  instructor_ids       :string
#  location_ids         :string
#  time_range_start     :string
#  time_range_end       :string
#

class LineItem < ApplicationRecord

  has_many :redemption_keys

  has_attached_file :display,
    styles: { :medium => "300x300>", :thumb => "100x100#" },
    :default_url => "http://parkourutah.com/images/missing.png",
    :storage => :s3,
    :bucket => ENV['PKUT_S3_BUCKET_NAME'],
    :convert_options => { :all => '-background white -flatten +matte' }
  validates_attachment_content_type :display, :content_type => /\Aimage\/.*\Z/

  before_save :assign_item_position_if_nil
  before_destroy :destroy_keys

  def users_who_purchased
    User.joins(carts: [cart_items: [:line_item]]).where(line_items: {id: self.id}).where.not(carts: {purchased_at: nil}).distinct
  end

  def redemption_item
    LineItem.find(redemption_item_id)
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

  def tax
    self.taxable? ? (self.cost.to_f * 0.0825).round : 0
  end

  def assign_item_position_if_nil
    unless self.item_order
      self.item_order = (LineItem.all.map { |l| l.item_order }.compact.sort.last + 1)
      self.save!
    end
  end

end
