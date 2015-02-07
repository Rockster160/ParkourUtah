class CreateEvents < ActiveRecord::Migration
  def change
    create_table :events do |t|
      t.datetime :date # Saturday, Feb 12, 2015 10:00 am
      t.string :title # Higgie's Homecoming Jam!
      t.integer :host_id #Justin, Higgie, Ryan, Christian - id of user
      t.float :cost #2.50
      t.text :description #Tricking session followed by lunch on us
      t.string :city #Draper, Salt Lake City, Sandy, Orem
      t.string :address #12500 South 1300 East
      t.string :location_instructions # Turn left there, park near the big tree
      t.string :class_name #Intermediate

      t.timestamps null: false
    end
  end
end
