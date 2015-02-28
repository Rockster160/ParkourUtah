class CreateLineItems < ActiveRecord::Migration
  def change
    create_table :line_items do |t|
      t.attachment :display
      t.text :description
      t.integer :cost_in_pennies
      t.string :title
      t.string :category

      t.timestamps null: false
    end
  end
end
