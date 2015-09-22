class CreateContactRequests < ActiveRecord::Migration
  def change
    create_table :contact_requests do |t|
      t.string :user_agent
      t.string :phone
      t.string :name
      t.string :email
      t.string :body
      t.boolean :success

      t.timestamps null: false
    end
  end
end
