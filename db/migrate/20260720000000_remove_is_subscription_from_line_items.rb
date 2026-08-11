class RemoveIsSubscriptionFromLineItems < ActiveRecord::Migration[8.1]
  def change
    remove_column :line_items, :is_subscription, :boolean, default: false
  end
end
