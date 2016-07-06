class AddTextClassCancelledReminderToNotification < ActiveRecord::Migration
  def change
    add_column :notifications, :text_class_cancelled, :boolean, default: false
    add_column :notifications, :email_class_cancelled, :boolean, default: false
    Notifications.all.each do |n|
      n.update(text_class_cancelled: true)
      n.update(email_class_cancelled: true)
    end
  end
end
