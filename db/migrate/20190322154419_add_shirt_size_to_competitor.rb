class AddShirtSizeToCompetitor < ActiveRecord::Migration[5.0]
  def change
    add_column :competitors, :shirt_size, :string
  end
end
