class RefactorEvents < ActiveRecord::Migration
  def change
    puts "\nCreating Event Schedule Table"
    create_table :event_schedules do |t|
      t.belongs_to :instructor, foreign_key: true, index: true
      t.belongs_to :spot, foreign_key: true, index: true

      t.datetime :start_date
      t.datetime :end_date
      t.integer :hour_of_day
      t.integer :minute_of_day
      t.integer :day_of_week

      t.integer :cost_in_pennies
      t.string :title
      t.text :description

      t.string :full_address
      t.string :city
      t.string :color

      t.timestamps
    end
    puts "\nAdding event -> schedule relationship"
    add_column :events, :event_schedule_id, :integer, foreign_key: true, index: true

    events_by_token = Event.where.not(token: nil).group_by(&:token)
    puts "\nBackfilling EventSchedules (#{events_by_token.count})"
    events_by_token.each do |token, events|
      next_event = events.sort_by(&:date).first
      last_event = events.sort_by(&:date).last
      possibles = User.instructors.by_fuzzy_text(next_event.host)
      instructor = possibles.one? ? possibles.first : nil
      db_attrs = next_event.attributes
      event_schedule = EventSchedule.create(
        instructor: instructor,
        start_date: next_event.date.to_datetime.beginning_of_day,
        end_date: last_event.date > DateTime.current ? nil : last_event.date.to_datetime.end_of_day,
        hour_of_day: next_event.date.to_datetime.hour,
        minute_of_day: next_event.date.to_datetime.minute,
        day_of_week: next_event.date.wday,
        cost_in_pennies: next_event.cost,
        title: db_attrs["class_name"],
        description: db_attrs["description"],
        full_address: db_attrs["address"],
        city: db_attrs["city"],
        color: db_attrs["color"]
      )
      Event.where(token: token).update_all(event_schedule_id: event_schedule.id)
      print "."
    end

    puts "\nAdd subscriptions to schedules (#{Subscription.count})"
    add_column :subscriptions, :event_schedule_id, :integer, foreign_key: true, index: true
    Subscription.all.each do |subscription|
      event = Event.find(subscription.event_id)
      subscription.update(event_schedule_id: event.event_schedule_id)
      print "."
    end

    puts "\nAdding Spots to Schedules (#{Spot.count})"
    Spot.all.each do |spot|
      spot_events = SpotEvent.where(spot_id: spot.id)
      event_schedule_ids = Event.where(id: spot_events.map(&:event_id)).group_by(&:event_schedule_id).keys
      EventSchedule.where(id: event_schedule_ids).update_all(spot_id: spot.id)
      print "."
    end

    puts "\nRemoving SpotEvents"
    drop_table :spot_events

    Event.in_the_future.where.not(token: nil).destroy_all
    add_column :events, :is_cancelled, :boolean, default: false
    remove_column :events, :token, :integer
    remove_column :events, :title, :string
    remove_column :events, :host, :string
    remove_column :events, :cost, :float
    remove_column :events, :description, :text
    remove_column :events, :city, :string
    remove_column :events, :address, :string
    remove_column :events, :location_instructions, :string
    remove_column :events, :zip, :string
    remove_column :events, :state, :string
    remove_column :events, :color, :string
    remove_column :events, :class_name, :string
    remove_column :events, :cancelled_text, :string
    remove_column :subscriptions, :event_id, :integer
    remove_column :subscriptions, :token, :integer
  end
end
