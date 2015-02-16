class CreateOrders < ActiveRecord::Migration
  def change
    create_table :orders do |t|
      t.belongs_to :cart, index: true
      t.integer :item_id

      t.timestamps null: false
    end
    add_foreign_key :orders, :carts
  end
end
