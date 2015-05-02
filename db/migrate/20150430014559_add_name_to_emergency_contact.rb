class AddNameToEmergencyContact < ActiveRecord::Migration
  def change
    add_column :emergency_contacts, :name, :string
  end
end
