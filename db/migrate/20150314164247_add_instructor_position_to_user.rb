class AddInstructorPositionToUser < ActiveRecord::Migration
  def change
    add_column :users, :instructor_position, :integer
  end
end
