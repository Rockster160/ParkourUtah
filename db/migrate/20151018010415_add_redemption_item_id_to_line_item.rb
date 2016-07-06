class AddRedemptionItemIdToLineItem < ActiveRecord::Migration
  def change
    add_column :line_items, :redemption_item_id, :integer
  end
end
