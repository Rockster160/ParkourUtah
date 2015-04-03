class ChangeRedemptionToIntegerOnRedemptionKeys < ActiveRecord::Migration
  def change
    add_reference :redemption_keys, :line_item, index: true
  end
end
