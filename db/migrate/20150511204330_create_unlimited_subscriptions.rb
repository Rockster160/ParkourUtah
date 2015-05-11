class CreateUnlimitedSubscriptions < ActiveRecord::Migration
  def change
    create_table :unlimited_subscriptions do |t|
      t.integer :usages, default: 0
      t.datetime :expires_at
      t.belongs_to :user, index: true

      t.timestamps null: false
    end
    add_foreign_key :unlimited_subscriptions, :users
  end
end
