class AddHiddentoLineItems < ActiveRecord::Migration
  def change
    add_column :line_items, :hidden, :boolean, defaut: false
  end
end
