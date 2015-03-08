class Dependent < ActiveRecord::Migration
  def change
    create_table :dependents do |t|
      t.belongs_to :user, index: true
      t.string :full_name
      t.integer :emergency_contact
      t.integer :athlete_id
      t.integer :athlete_pin
      t.attachment :athlete_photo

      t.timestamps null: false
    end
  end
end
