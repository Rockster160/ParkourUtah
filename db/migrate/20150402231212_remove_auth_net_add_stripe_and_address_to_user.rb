class RemoveAuthNetAddStripeAndAddressToUser < ActiveRecord::Migration
  def change
    remove_column :users, :shipping_id, :integer
    remove_column :users, :auth_net_id, :integer
    remove_column :users, :payment_id, :integer

    create_table :addresses do |t|
      t.belongs_to :user, index: true
      t.string  :line1
      t.string  :line2
      t.string  :city
      t.string  :state
      t.string  :zip

      t.timestamps null: false
    end
  end
end
