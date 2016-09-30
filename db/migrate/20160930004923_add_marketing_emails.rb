class AddMarketingEmails < ActiveRecord::Migration
  def change
    add_column :notifications, :email_newsletter, :boolean, default: true
  end
end
