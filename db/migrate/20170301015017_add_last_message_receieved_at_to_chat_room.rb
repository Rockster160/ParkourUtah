class AddLastMessageReceievedAtToChatRoom < ActiveRecord::Migration[5.0]
  def change
    add_column :chat_rooms, :last_message_received_at, :datetime
  end
end
