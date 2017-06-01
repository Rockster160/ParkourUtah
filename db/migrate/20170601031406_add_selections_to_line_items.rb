class AddSelectionsToLineItems < ActiveRecord::Migration[5.0]
  def change
    add_column :line_items, :instructor_ids, :string
    add_column :line_items, :location_ids, :string
    add_column :line_items, :time_range_start, :string
    add_column :line_items, :time_range_end, :string
  end
end
