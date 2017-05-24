class AddTextToImage < ActiveRecord::Migration[5.0]
  def change
    add_column :line_items, :show_text_as_image, :boolean, default: true
  end
end
