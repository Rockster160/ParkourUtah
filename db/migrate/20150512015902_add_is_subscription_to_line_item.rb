class AddIsSubscriptionToLineItem < ActiveRecord::Migration
  def change
    add_column :line_items, :is_subscription, :boolean, default: false
  end
end
