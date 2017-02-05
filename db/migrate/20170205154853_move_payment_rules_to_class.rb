class MovePaymentRulesToClass < ActiveRecord::Migration[5.0]
  def change
    remove_column :users, :payment_multiplier, :integer
    add_column :event_schedules, :payment_per_student, :integer
    add_column :event_schedules, :min_payment_per_session, :integer
    add_column :event_schedules, :max_payment_per_session, :integer
    add_column :event_schedules, :accepts_unlimited_classes, :boolean, default: true
    add_column :event_schedules, :accepts_trial_classes, :boolean, default: true

    EventSchedule.update_all(payment_per_student: 4, min_payment_per_session: 15)
  end
end
