class AddPaymentMultipleToUser < ActiveRecord::Migration
  def change
    add_column :users, :payment_multiplier, :integer, default: 3
  end
end
