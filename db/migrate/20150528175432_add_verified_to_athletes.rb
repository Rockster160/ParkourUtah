class AddVerifiedToAthletes < ActiveRecord::Migration
  def change
    add_column :dependents, :verified, :boolean, default: false
  end
end
