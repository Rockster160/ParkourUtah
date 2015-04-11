class AddPersonalInfoToUsers < ActiveRecord::Migration
  def change
    add_column :users, :date_of_birth, :datetime
    add_column :users, :drivers_license_number, :string
    add_column :users, :drivers_license_state, :string
  end
end
