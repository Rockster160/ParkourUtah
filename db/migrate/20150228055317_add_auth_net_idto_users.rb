class AddAuthNetIdtoUsers < ActiveRecord::Migration
  def change
    add_column :users, :auth_net_id, :integer
    add_column :users, :payment_id, :integer
    add_column :users, :credits, :integer, default: 0
  end
end
