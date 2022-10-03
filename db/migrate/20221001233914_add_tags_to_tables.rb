class AddTagsToTables < ActiveRecord::Migration[6.1]
  def change
    create_table :plan_items do |t|
      t.text :name
      t.jsonb :free_items
      t.jsonb :discount_items

      t.timestamps
    end

    create_table :purchased_plan_items do |t|
      t.belongs_to :user
      t.belongs_to :athlete
      t.belongs_to :cart
      t.belongs_to :plan_item

      t.integer :cost_in_pennies
      t.datetime :expires_at
      t.boolean :auto_renew, default: true
      t.text :stripe_id
      t.text :card_declined

      t.jsonb :free_items
      t.jsonb :discount_items

      t.timestamps
    end

    add_reference :line_items, :plan_item
    add_reference :attendances, :purchased_plan_item

    add_column :event_schedules, :tags, :jsonb
    add_column :line_items, :tags, :jsonb
  end
end
