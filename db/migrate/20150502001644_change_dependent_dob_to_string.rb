class ChangeDependentDobToString < ActiveRecord::Migration
  def up
    change_column :dependents, :date_of_birth, :string
  end

  def down
    change_column :dependents, :date_of_birth, :datetime
  end
end
