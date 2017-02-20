class AddErrorsToMessages < ActiveRecord::Migration[5.0]
  def change
    remove_column :messages, :sent_to_user, :boolean
    add_column :messages, :error, :boolean, default: false
    add_column :messages, :error_message, :string
  end
end
