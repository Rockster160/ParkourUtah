class AddInfoToDependents < ActiveRecord::Migration
  def change
    add_column :dependents, :first_name, :string
    add_column :dependents, :middle_name, :string
    add_column :dependents, :last_name, :string
    add_column :dependents, :date_of_birth, :datetime
  end
end
