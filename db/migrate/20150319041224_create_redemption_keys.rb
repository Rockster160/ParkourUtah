class CreateRedemptionKeys < ActiveRecord::Migration
  def change
    create_table :redemption_keys do |t|
      t.string :key
      t.string :redemption

      t.timestamps null: false
    end
  end
end
