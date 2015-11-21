class CreateVenmos < ActiveRecord::Migration
  def change
    create_table :venmos do |t|
      t.string :access_token
      t.string :refresh_token
      t.datetime :expires_at
      t.string :username

      t.timestamps null: false
    end
    Venmo.create(username: "Rocco")
  end
end
