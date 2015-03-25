class AddRedeemedTokenToTransactions < ActiveRecord::Migration
  def change
    add_column :transactions, :redeemed_token, :string
  end
end
