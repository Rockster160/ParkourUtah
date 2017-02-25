class RenameDependent < ActiveRecord::Migration[5.0]
  def change
    rename_table :dependents, :athletes
    rename_table :athlete_subscriptions, :recurring_subscriptions
    rename_table :subscriptions, :event_subscriptions

    rename_column :athletes, :athlete_id, :fast_pass_id
    rename_column :athletes, :athlete_pin, :fast_pass_pin

    rename_column :recurring_subscriptions, :dependent_id, :athlete_id
    rename_column :attendances, :dependent_id, :athlete_id
    rename_column :trial_classes, :dependent_id, :athlete_id
    rename_column :waivers, :dependent_id, :athlete_id

    add_column :recurring_subscriptions, :stripe_id, :string
  end
end
