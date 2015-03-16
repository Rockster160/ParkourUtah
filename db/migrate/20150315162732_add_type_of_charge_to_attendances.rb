class AddTypeOfChargeToAttendances < ActiveRecord::Migration
  def change
    add_column :attendances, :type_of_charge, :string
  end
end
