class AddReceivableToNotifications < ActiveRecord::Migration
  def change
    add_column :notifications, :sms_receivable, :boolean
  end
end
