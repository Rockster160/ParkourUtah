class AddReferredByToCompetitor < ActiveRecord::Migration[5.0]
  def change
    add_column :competitors, :referred_by, :string
  end
end
