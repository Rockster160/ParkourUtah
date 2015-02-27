class AddSizeToLineItems < ActiveRecord::Migration
  def change
    add_column :line_items, :size, :string
  end
end
