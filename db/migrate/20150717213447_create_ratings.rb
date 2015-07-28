class CreateRatings < ActiveRecord::Migration
  def change
    create_table :ratings do |t|
      t.integer :rated
      t.belongs_to :spot, index: true

      t.timestamps null: false
    end
    add_foreign_key :ratings, :spots
  end
end
