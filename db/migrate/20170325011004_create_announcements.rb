class CreateAnnouncements < ActiveRecord::Migration[5.0]
  def change
    create_table :announcements do |t|
      t.integer :admin_id, foreign_key: true, index: true
      t.datetime :expires_at
      t.text :body
      t.datetime :delivered_at

      t.timestamps
    end
  end
end
