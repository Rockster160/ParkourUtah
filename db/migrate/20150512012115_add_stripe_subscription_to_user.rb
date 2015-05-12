class AddStripeSubscriptionToUser < ActiveRecord::Migration
  def change
    add_column :users, :stripe_subscription, :boolean, default: false
  end
end
