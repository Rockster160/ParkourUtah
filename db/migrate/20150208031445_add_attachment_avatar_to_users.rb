class AddAttachmentAvatarToUsers < ActiveRecord::Migration
  def self.up
    change_table :users do |t|
      t.attachment :avatar
      t.attachment :avatar_2
    end
  end

  def self.down
    remove_attachment :users, :avatar
    remove_attachment :users, :avatar_2
  end
end
