class AddLoyaltyCostToLineItems < ActiveRecord::Migration[8.1]
  def change
    add_column :line_items, :loyalty_cost_in_pennies, :integer
  end
end
