class FixNotificationAttributes < ActiveRecord::Migration
  def change
    rename_column :notifications, :text_class_remainder, :text_class_reminder
    rename_column :notifications, :email_expiring, :email_waiver_expiring
    rename_column :notifications, :text_expiring, :text_waiver_expiring
  end
end
