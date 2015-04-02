class RemoveAuthNetAddStripeAndAddressToUser < ActiveRecord::Migration
  def change
    remove_column :users, :shipping_id
    remove_column :users, :auth_net_id
    remove_column :users, :payment_id

    create_table :addresses do |t|
      t.string  :line1
      t.string  :line2
      t.string  :city
      t.string  :state
      t.string  :zip

      t.timestamps null: false
    end
  end
end
