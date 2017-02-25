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
    add_column :recurring_subscriptions, :user_id, :integer, foreign_key: true, index: true
  end
end
=begin
  <Rename `email_subscription` to `can_receive_emails`>

  <move `sms_receivable` from :notifications to :users>
  add_column :users, :sms_receivable, :boolean, default: true
  Notifications.each update user sms_receivable
  remove_column :notifications, :sms_receivable, :boolean

  drop_table :unlimited_subscriptions
  <delete unlimited_subscriptions file/model>

  For each user, iterate by unassigned_subscriptions_count and create a new
  recurring_subscription that's not assigned to an athlete

  For each recurring_subscription, update the Stripe ID to match the User's
  stripe_id

  remove_column :users, :stripe_id
  remove_column :users, :stripe_subscription
  remove_column :users, :subscription_cost
=end
