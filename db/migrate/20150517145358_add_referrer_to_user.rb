class AddReferrerToUser < ActiveRecord::Migration
  def change
    add_column :users, :referrer, :string, default: ''
  end
end
