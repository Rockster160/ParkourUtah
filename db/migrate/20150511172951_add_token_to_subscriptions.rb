class AddTokenToSubscriptions < ActiveRecord::Migration
  def change
    add_column :subscriptions, :token, :integer
  end
end
