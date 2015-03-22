class AddRedeemedToRedemptionsKeys < ActiveRecord::Migration
  def change
    add_column :redemption_keys, :redeemed, :boolean, default: false
  end
end
