class AddShippingIdToUsers < ActiveRecord::Migration
  def change
    add_column :users, :shipping_id, :string
  end
end
