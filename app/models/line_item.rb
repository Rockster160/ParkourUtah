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
#

class LineItem < ActiveRecord::Base

  has_many :redemption_keys

  has_attached_file :display,
    styles: { :medium => "300x300>", :thumb => "100x100#" },
    :default_url => "/images/missing.png",
    :storage => :s3,
    :bucket => ENV['PKUT_S3_BUCKET_NAME'],
    :convert_options => { :all => '-background white -flatten +matte' }
  validates_attachment_content_type :display, :content_type => /\Aimage\/.*\Z/

  before_save :assign_item_position_if_nil
  before_destroy :destroy_keys

  default_scope { order('item_order ASC') }

  def destroy_keys
    Transaction.all.select { |t| t.item.id == self.id}.each { |order| order.destroy }
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

  def cost
    self.cost_in_pennies
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
