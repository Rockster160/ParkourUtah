class AddAuthNetIdtoUsers < ActiveRecord::Migration
  def change
    add_column :users, :auth_net_id, :integer
  end
end
