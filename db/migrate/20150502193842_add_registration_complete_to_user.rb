class AddRegistrationCompleteToUser < ActiveRecord::Migration
  def change
    add_column :users, :registration_complete, :boolean, default: false
  end
end
