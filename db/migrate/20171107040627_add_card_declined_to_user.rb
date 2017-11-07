class AddCardDeclinedToUser < ActiveRecord::Migration[5.0]
  def change
    add_column :recurring_subscriptions, :card_declined, :boolean
  end
end
