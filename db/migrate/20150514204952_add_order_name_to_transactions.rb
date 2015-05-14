class AddOrderNameToTransactions < ActiveRecord::Migration
  def change
    add_column :transactions, :order_name, :string
  end
end
