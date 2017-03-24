class FixTextMessages < ActiveRecord::Migration[5.0]
  def change
    rename_table :text_messages, :messages

    rename_column :messages, :instructor_id, :sent_from_id
    add_column :messages, :sent_to_id, :integer, index: true, foreign_key: true

    remove_column :messages, :read_by_instructor, :boolean
    add_column :messages, :read_at, :timestamp

    add_column :messages, :message_type, :integer

    # Message.update_all(message_type: Message.message_types[:text])
    # ContactRequest.all.each do |contact|
    #   contact.log_message
    # end
  end
end
