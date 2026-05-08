class AddBundledLoyaltyCostToLineItems < ActiveRecord::Migration[8.1]
  def change
    add_column :line_items, :bundled_loyalty_cost_in_pennies, :integer
  end
end
