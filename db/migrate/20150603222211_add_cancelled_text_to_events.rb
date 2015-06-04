class AddCancelledTextToEvents < ActiveRecord::Migration
  def change
    add_column :events, :cancelled_text, :boolean, default: false
  end
end
