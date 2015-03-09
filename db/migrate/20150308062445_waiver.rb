class Waiver < ActiveRecord::Migration
  def change
    create_table :waivers do |t|
      t.belongs_to :dependent, index: true
      t.boolean :signed
      t.string :signed_for
      t.string :signed_by

      t.timestamps null: false
    end
  end
end
