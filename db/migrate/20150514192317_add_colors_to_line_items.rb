class AddColorsToLineItems < ActiveRecord::Migration
  def change
    add_column :line_items, :color, :string
  end
end
