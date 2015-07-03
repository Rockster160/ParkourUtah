class CreateAthleteSubscriptions < ActiveRecord::Migration
  def change
    create_table :athlete_subscriptions do |t|
      t.belongs_to :dependent, index: true
      t.integer :usages, default: 0
      t.datetime :expires_at
      t.integer :cost_in_pennies, default: 0
      t.boolean :auto_renew, default: true

      t.timestamps null: false
    end
    add_foreign_key :athlete_subscriptions, :dependents
  end
end
