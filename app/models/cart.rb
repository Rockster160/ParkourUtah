# == Schema Information
#
# Table name: carts
#
#  id           :integer          not null, primary key
#  user_id      :integer
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  email        :string
#  purchased_at :datetime
#

class Cart < ApplicationRecord
  include ActionView::Helpers::NumberHelper

  belongs_to :user, optional: true
  has_many :cart_items, dependent: :destroy

  scope :purchased, -> { where.not(purchased_at: nil) }

  def notify_slack_of_purchase
    if user.present?
      user_url = Rails.application.routes.url_helpers.admin_user_url(user)
      user_url_text = user.present? ? "<#{user_url}|Click here to view their profile.>" : ""
    end
    slack_message = "#{user.try(:email) || email} has just made a purchase. #{user_url_text}\n"

    if is_physical?
      address = user.address
      slack_message << "*Shipping information*\n"
      slack_message << "> #{address.line1}\n"
      slack_message << "> #{address.line2}\n"
      slack_message << "> #{address.city}\n"
      slack_message << "> #{address.state}\n"
      slack_message << "> #{address.zip}\n\n"
    end

    max_name = [10, cart_items.map(&:order_name).map(&:to_s).map(&:length)].flatten.max + 2
    max_quantity = [2, cart_items.map(&:amount).map(&:to_s).map(&:length)].flatten.max + 2
    max_cost = [5, cart_items.map(&:line_item).map(&:cost_in_pennies).map(&:to_s).map(&:length)].flatten.max + 12

    slack_message << "```"
    cart_items.each do |cart_item|
      exceeds_bundle = cart_item.line_item.exceeds_bundle?(cart_item.amount)
      cost_str = exceeds_bundle ? "bundle #{number_to_currency(cart_item.line_item.bundle_cost)}".rjust(max_cost) : "#{number_to_currency(cart_item.line_item.cost_in_dollars).rjust(max_cost)}"

      slack_message << "#{cart_item.order_name.ljust(max_name)} #{cart_item.amount.to_s.rjust(max_quantity)}x #{cost_str}\n"
    end
    slack_message << "#{'-- Tax:'.ljust(max_name)} #{''.rjust(max_quantity)}  #{number_to_currency(taxes_in_dollars).rjust(max_cost)}\n" if taxes > 0
    slack_message << "#{'-- Shipping:'.ljust(max_name)} #{''.rjust(max_quantity)}  #{number_to_currency(shipping_in_dollars).rjust(max_cost)}\n" if shipping > 0
    slack_message << "#{'-- Total:'.ljust(max_name)} #{''.rjust(max_quantity)}  #{number_to_currency(total_in_dollars).rjust(max_cost)}\n"
    slack_message << "```"

    if Rails.env.production?
      SlackNotifier.notify(slack_message, "#special-purchases") if cart_items.any? { |cart_item| [2, 15].include?(cart_item.line_item_id) || cart_item.try(:line_item).try(:time_range_start).present? }
      SlackNotifier.notify(slack_message, "#purchases") if cart_items.any? { |cart_item| [2, 15].exclude?(cart_item.line_item_id) }
    else
      SlackNotifier.notify(slack_message, "#slack-testing")
    end
  end

  def is_gift_card?
    cart_items.any? { |cart_item| ["Gift Card"].include?(cart_item.item.category) }
  end
  def is_physical?
    cart_items.any? { |cart_item| ["Clothing", "Accessories"].include?(cart_item.item.category) }
  end
  def adds_credits?
    cart_items.any? { |cart_item| cart_item.item.credits > 0 }
  end
  def is_subscription?
    cart_items.any? { |cart_item| cart_item.item.is_subscription? }
  end

  def purchased?
    purchased_at?
  end

  def items
    items = []
    self.cart_items.each do |order|
      order.amount.times do
        items <<  LineItem.find(order.line_item_id)
      end
    end
    items
  end

  def add_items(*item_ids)
    item_ids.flatten.each do |item_id|
      order = cart_items.where(line_item_id: item_id).first
      if order
        order.increment!(:amount)
      else
        item = LineItem.find(item_id)
        cart_items.create(line_item_id: item_id, order_name: item.title, amount: 1)
      end
    end
  end

  def price
    cost = 0
    self.cart_items.each do |order|
      cost += order.item.cost_for(order.amount, user)
    end
    cost <= 0 ? 0 : cost
  end

  def shipping
    cost = 0
    self.cart_items.each do |order|
      cost += (order.amount * 200) unless %w( Class Coupon Redemption Other Gift\ Card ).include?(order.item.category)
    end
    cost += (cost > 0 ? 300 : 0)
    cost
  end

  def taxes
    cost = 0
    self.cart_items.each do |order|
      cost += order.item.tax_for(order.amount, user)
    end
    cost
  end

  def total
    self.price + self.shipping + self.taxes
  end

  def price_in_dollars
    (self.price.to_f / 100).round(2)
  end

  def shipping_in_dollars
    (self.shipping.to_f / 100).round(2)
  end

  def taxes_in_dollars
    (self.taxes.to_f / 100).round(2)
  end

  def total_in_dollars
    (self.total.to_f / 100).round(2)# <= 0 ? 0 : (self.total.to_f / 100).round(2)
  end

end
