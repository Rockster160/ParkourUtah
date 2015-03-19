class Attendance < ActiveRecord::Migration
  def change
    create_table :attendances do |t|
      t.belongs_to :dependent, index: true
      t.belongs_to :user, index: true
      t.belongs_to :event, index: true
      t.string :location

      t.timestamps null: false
    end
  end
end
