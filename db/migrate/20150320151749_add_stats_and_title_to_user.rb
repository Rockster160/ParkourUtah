class AddStatsAndTitleToUser < ActiveRecord::Migration
  def change
    add_column :users, :stats, :string
    add_column :users, :title, :string
  end
end
