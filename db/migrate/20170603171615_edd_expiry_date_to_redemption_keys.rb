class EddExpiryDateToRedemptionKeys < ActiveRecord::Migration[5.0]
  def change
    add_column :redemption_keys, :expires_at, :datetime
  end
end
