class RenameDependent < ActiveRecord::Migration[5.0]
  def change
    rename_table :dependents, :athletes
    rename_table :athlete_subscriptions, :recurring_subscriptions
    rename_table :subscriptions, :event_subscriptions

    rename_column :athletes, :athlete_id, :fast_pass_id
    rename_column :athletes, :athlete_pin, :fast_pass_pin
    rename_column :users, :email_subscription, :can_receive_emails

    rename_column :recurring_subscriptions, :dependent_id, :athlete_id
    rename_column :attendances, :dependent_id, :athlete_id
    rename_column :trial_classes, :dependent_id, :athlete_id
    rename_column :waivers, :dependent_id, :athlete_id

    add_column :users, :can_receive_sms, :boolean, default: true
    add_column :users, :full_name, :string
    add_column :recurring_subscriptions, :stripe_id, :string
    add_column :recurring_subscriptions, :user_id, :integer, foreign_key: true, index: true

    reversible do |migration|
      migration.up do
        puts "\e[31mMigrating UP!\e[0m"
        puts "Backfill user attached to subscriptions"
        RecurringSubscription.find_each do |subscription|
          print subscription.update(user_id: subscription.try(:athlete).try(:user_id)) ? "\e[32m.\e[0m" : "\e[31m.\e[0m"
        end
        puts ""
        User.find_each do |user|
          print "#{user.id}"
          # Move SMS receivable to User
          print user.update(can_receive_sms: user.try(:notifications).try(:sms_receivable)) ? "\e[32m.\e[0m" : "\e[31m.\e[0m"
          # Backfill unassigned subscriptions
          user.unassigned_subscriptions_count.times do
            print user.recurring_subscriptions.create(cost_in_pennies: user.subscription_cost, stripe_id: user.stripe_id).persisted? ? "\e[32m.\e[0m" : "\e[31m.\e[0m"
          end
          # Backfill full_name
          print user.update(full_name: "#{user.first_name} #{user.last_name}".squish.titleize.presence) ? "\e[32m.\e[0m" : "\e[31m.\e[0m"
        end
      end
      migration.down do
        puts "\e[31mMigrating DOWN!\e[0m"
      end
    end
  end
end
=begin
BACKUP THE DATABASE BEFORE REMOVING THESE ATTRIBUTES
  remove_column :notifications, :sms_receivable, :boolean

  drop_table :unlimited_subscriptions
  <delete unlimited_subscriptions file/model>

  remove_column :users, :stripe_id
  remove_column :users, :stripe_subscription
  remove_column :users, :subscription_cost
  remove_column :users, :first_name
  remove_column :users, :last_name
  remove_column :users, :date_of_birth
  remove_column :users, :drivers_license_number
  remove_column :users, :drivers_license_state
  remove_column :users, :reset_password_token
  remove_column :users, :confirmation_token
=end
