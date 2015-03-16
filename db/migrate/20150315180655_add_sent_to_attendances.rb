class AddSentToAttendances < ActiveRecord::Migration
  def change
    add_column :attendances, :sent, :boolean, default: false
  end
end
