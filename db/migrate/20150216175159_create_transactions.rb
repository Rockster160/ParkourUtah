class CreateTransactions < ActiveRecord::Migration
  def change
    create_table :transactions do |t|
      t.belongs_to :cart, index: true
      t.integer :item_id
      t.integer :amount, default: 1

      t.timestamps null: false
    end
    add_foreign_key :transactions, :carts
  end
end
