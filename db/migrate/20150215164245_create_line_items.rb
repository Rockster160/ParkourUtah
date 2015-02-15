class CreateLineItems < ActiveRecord::Migration
  def change
    create_table :line_items do |t|
      t.attachment :display
      t.text :description
      t.float :cost
      t.string :title

      t.timestamps null: false
    end
  end
end
