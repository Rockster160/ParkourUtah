class CreateEventReminders < ActiveRecord::Migration[5.0]
  def change
    create_table :event_reminders do |t|
      t.belongs_to :event_schedule
      t.integer :relative_time_difference
      t.text :message
    end

    EventSchedule.find_each do |schedule|
      schedule.event_reminders.create
    end
  end
end
