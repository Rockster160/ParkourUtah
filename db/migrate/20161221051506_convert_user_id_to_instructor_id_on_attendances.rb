class ConvertUserIdToInstructorIdOnAttendances < ActiveRecord::Migration
  def change
    rename_column :attendances, :user_id, :instructor_id
  end
end
