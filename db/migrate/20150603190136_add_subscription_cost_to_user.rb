class AddSubscriptionCostToUser < ActiveRecord::Migration
  def change
    add_column :users, :subscription_cost, :integer, default: 5000
  end
end
