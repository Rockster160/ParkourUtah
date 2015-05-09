class AddRegistrationStepToUser < ActiveRecord::Migration
  def change
    add_column :users, :registration_step, :integer, default: 2
  end
end
