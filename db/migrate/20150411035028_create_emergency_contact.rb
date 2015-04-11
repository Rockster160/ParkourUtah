class CreateEmergencyContact < ActiveRecord::Migration
  def change
    create_table :emergency_contacts do |t|
      t.belongs_to :user, index: true
      t.string :number
    end
    add_foreign_key :emergency_contacts, :users
  end
end
