class AddMaxQuantityToRedemptionKeys < ActiveRecord::Migration[8.1]
  def change
    # Nullable on purpose: nil keeps the old behavior (one unit per code, unless
    # the key is flagged multi-use), so existing keys are unaffected.
    add_column :redemption_keys, :max_quantity, :integer
  end
end
