class AddBundleAmountAndPriceToLineItems < ActiveRecord::Migration[5.0]
  def change
    add_column :line_items, :bundle_amount, :integer
    add_column :line_items, :bundle_cost_in_pennies, :integer
  end
end
