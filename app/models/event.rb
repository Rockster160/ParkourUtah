class Event < ActiveRecord::Base
  # create_table "events", force: :cascade do |t|
  #   t.datetime "date"
  #   t.integer  "token"
  #   t.string   "title"
  #   t.string   "host"
  #   t.float    "cost"
  #   t.text     "description"
  #   t.string   "city"
  #   t.string   "address"
  #   t.string   "location_instructions"
  #   t.string   "class_name"
  #   t.datetime "created_at",            null: false
  #   t.datetime "updated_at",            null: false
  # end

  has_many :attendances

  def host_by_id
    User.find(host)
  end

  def send_text
    ::SmsMailerWorker.perform_async(Time.now.to_s, ['3852599640'])
  end

  def send_summary
    classes = {}
    instructors = {}
    Event.select {|e| e.date.to_date == Time.now.to_date}.each do |event|

      event.attendances.each do |a|
        instructor = User.find(a.instructor_id).full_name
        instructors[instructor] ||= []
        athlete = Dependent.where(athlete_id: a.dependent_id).first
        instructors[instructor] << "#{athlete.full_name} - #{a.type_of_charge}"
      end

      classes["#{event.class_name.capitalize} - #{event.city}"] = instructors
    end
    ::AttendanceMailerWorker.perform_async(classes)
  end

  def send_weekly_summary
    weekly_summary = {}
    payment = {}

    (0..6).each do |day|
      classes = {}
      instructors = {}
      Event.select {|e| e.date.to_date == Time.now.to_date - day}.each do |event|
        event.attendances.each do |a|
          instructor = User.find(a.instructor_id)
          instructors[instructor.full_name] ||= {}
          instructors[instructor.full_name]["students"] ||= []
          instructors[instructor.full_name]["pay"] ||= 0

          athlete = Dependent.where(athlete_id: a.dependent_id).first
          instructors[instructor.full_name]["students"] << "#{athlete.full_name} - #{a.type_of_charge}"
          instructors[instructor.full_name]["pay"] += instructor.payment_multiplier

          payment[instructor.full_name] ||= 0
          payment[instructor.full_name] += instructor.payment_multiplier
        end
        
        classes["#{event.class_name.capitalize} - #{event.city}"] = instructors
      end
      weekly_summary[(Time.now.to_date - day).strftime("%A - %B %-d, %Y")] = classes
    end

    summary = [weekly_summary, payment]

    ::WeeklySummaryMailerWorker.perform_async(summary)
  end

  private

end
=begin
day-x {                 .√
  class-x {             .√
    instructor-x {      .√
      pay = x,          .√
      students [        .√
        athlete-x       .√
      ]
    }
  }
}
=end
