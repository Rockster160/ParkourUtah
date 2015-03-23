class AddCreditsToLineItems < ActiveRecord::Migration
  def change
    add_column :line_items, :credits, :integer, default: 0
  end
end
