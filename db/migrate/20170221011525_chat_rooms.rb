class ChatRooms < ActiveRecord::Migration[5.0]
  def change
    create_table :chat_rooms do |t|
      t.string :name
      t.integer :visibility_level

      t.timestamps
    end

    create_table :chat_room_users do |t|
      t.belongs_to :chat_room, foreign_key: true, index: true
      t.belongs_to :user, foreign_key: true, index: true
      t.boolean :has_unread_messages, default: true
      t.boolean :notify_via_email, default: true
      t.boolean :notify_via_css, default: false
      t.boolean :muted, default: false

      t.timestamps
    end

    add_column :messages, :chat_room_id, :integer, foreign_key: true, index: true
    add_column :chat_room_users, :banned, :boolean, default: false
    add_column :chat_rooms, :message_type, :integer

    Message.find_each do |msg|
      room = ChatRoom.find_or_create_by(name: msg.phone_number)
      if room.persisted?
        msg.update(chat_room_id: room.id)

        room.chat_room_users.create(chat_room_id: room.id, user_id: msg.sent_to_id) if msg.sent_to.present?
        room.chat_room_users.create(chat_room_id: room.id, user_id: msg.sent_from_id) if msg.sent_from.present?
      end
    end
    ChatRoom.find_each do |room|
      msg = room.messages.order(created_at: :desc).first
      room.update(updated_at: msg.created_at)
    end

    remove_column :messages, :sent_to_id, :integer
    remove_column :messages, :stripped_phone_number, :integer
  end
end
