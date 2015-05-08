class CreateAutomators < ActiveRecord::Migration
  def change
    create_table :automators do |t|
      t.boolean :open, default: false

      t.timestamps null: false
    end
  end
end
