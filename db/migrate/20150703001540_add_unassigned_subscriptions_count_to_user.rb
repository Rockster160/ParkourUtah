class AddUnassignedSubscriptionsCountToUser < ActiveRecord::Migration
  def change
    add_column :users, :unassigned_subscriptions_count, :integer, default: 0
  end
end
