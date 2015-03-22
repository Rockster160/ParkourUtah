class AddItemOrderToLineItems < ActiveRecord::Migration
  def change
    add_column :line_items, :item_order, :integer
  end
end
