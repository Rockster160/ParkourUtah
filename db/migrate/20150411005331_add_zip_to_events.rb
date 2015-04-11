class AddZipToEvents < ActiveRecord::Migration
  def change
    add_column :events, :zip, :string
    add_column :events, :state, :string, default: "Utah"
    add_column :events, :color, :integer
  end
end
