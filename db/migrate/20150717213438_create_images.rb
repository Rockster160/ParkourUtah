class CreateImages < ActiveRecord::Migration
  def self.up
    change_table :images do |t|
      t.attachment :file
    end
  end

  def change
    create_table :images do |t|
      t.belongs_to :spot, index: true

      t.timestamps null: false
    end
    add_foreign_key :images, :spots
  end

  def self.down
    remove_attachment :images, :file
  end
end
