class CreateTextMessageLogs < ActiveRecord::Migration[5.0]
  def change
    create_table :text_messages do |t|
      t.integer :instructor_id, foreign_key: true, index: true
      t.boolean :read_by_instructor, default: false
      t.boolean :sent_to_user
      t.string :stripped_phone_number
      t.text :body

      t.timestamps
    end
  end
end
