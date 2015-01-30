class CreateEvents < ActiveRecord::Migration
  def change
    create_table :events do |t|
      t.datetime :when # Saturday, Feb 12, 2015 10:00 am
      t.string :host #Justin, Higgie, Ryan, Christian
      t.float :cost #2.50
      t.text :description #Tricking session followed by lunch on us
      t.string :location #Draper Park, UofU Student Building, 123 Parkour Street
      t.string :class_name #Intermediate

      t.timestamps null: false
    end
  end
end
