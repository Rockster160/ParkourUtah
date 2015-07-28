class CreateSpots < ActiveRecord::Migration
  def change
    create_table :spots do |t|
      t.string :title
      t.text :description
      t.string :lon
      t.string :lat
      t.boolean :approved, default: false
      t.belongs_to :event, index: true

      t.timestamps null: false
    end
    add_foreign_key :spots, :events
  end
end
