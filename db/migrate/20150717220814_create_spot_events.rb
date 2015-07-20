class CreateSpotEvents < ActiveRecord::Migration
  def change
    create_table :spot_events do |t|
      t.belongs_to :spot, index: true
      t.belongs_to :event, index: true

      t.timestamps null: false
    end
    add_foreign_key :spot_events, :spots
    add_foreign_key :spot_events, :events
  end
end
