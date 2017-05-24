class CreateLogTracker < ActiveRecord::Migration[5.0]
  def change
    create_table :log_trackers do |t|
      t.string :user_agent
      t.string :ip_address
      t.string :http_method
      t.string :url
      t.string :params
      t.belongs_to :user

      t.timestamps
    end
  end
end
