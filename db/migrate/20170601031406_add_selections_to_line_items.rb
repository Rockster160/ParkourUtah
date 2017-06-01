class AddSelectionsToLineItems < ActiveRecord::Migration[5.0]
  def change
    add_column :line_items, :instructor_ids, :string
    add_column :line_items, :location_ids, :string
    add_column :line_items, :select_time, :boolean
  end
end
