class AddRedeemedToRedemptionsKeys < ActiveRecord::Migration
  def change
    add_column :redemptions_keys, :redeemed, :boolean, default: false
  end
end
