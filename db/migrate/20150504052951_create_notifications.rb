class CreateNotifications < ActiveRecord::Migration
  def change
    create_table :notifications do |t|
      t.belongs_to :user, index: true
      t.boolean :email_class_reminder, default: false
      t.boolean :text_class_remainder, default: false
      t.boolean :email_low_credits, default: false
      t.boolean :text_low_credits, default: false
      t.boolean :email_expiring, default: false
      t.boolean :text_expiring, default: false
    end
    add_foreign_key :notifications, :users
  end
end
