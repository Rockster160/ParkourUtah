class AddIsFullImageToLineItem < ActiveRecord::Migration
  def change
    add_column :line_items, :is_full_image, :boolean, default: false
  end
end
