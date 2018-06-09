class AddApprovedAtToCompetitor < ActiveRecord::Migration[5.0]
  def change
    add_column :competitors, :approved_at, :datetime
  end
end
