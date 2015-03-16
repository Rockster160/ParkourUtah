class Scheduled < ActiveRecord::Base

  def self.send_text
    ::SmsMailerWorker.perform_async("Class tonight!", ['3852599640'])
  end

  def self.send_summary
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

  def self.send_weekly_summary
    weekly_summary = {}
    payment = {}

    (0..6).each do |day|
      classes = {}
      daily_payment = {}
      Event.select {|e| e.date.to_date == Time.now.to_date - day}.each do |event|
        instructors = {}
        class_payment = {}
        event.attendances.each do |a|
          instructor = User.find(a.instructor_id)
          instructors[instructor.full_name] ||= {}
          instructors[instructor.full_name]["students"] ||= []
          instructors[instructor.full_name]["pay"] ||= 0

          athlete = Dependent.where(athlete_id: a.dependent_id).first
          instructors[instructor.full_name]["students"] << "#{athlete.full_name} - #{a.type_of_charge}"
          instructors[instructor.full_name]["pay"] += instructor.payment_multiplier

          class_payment[instructor.full_name] ||= 0
          class_payment[instructor.full_name] += instructor.payment_multiplier
        end
        classes["#{event.class_name.capitalize} - #{event.city}"] = instructors
        class_payment.each do |instructor, pay|
          payment[instructor] ||= 0
          binding.pry if instructor == "Stephen Lanteri"
          payment[instructor] += (pay < 15 ? 15 : pay)
        end
      end
      weekly_summary[(Time.now.to_date - day).strftime("%A - %B %-d, %Y")] = classes
    end

    summary = [weekly_summary, payment]

    ::WeeklySummaryMailerWorker.perform_async(summary)
  end

  def self.attend_random_classes
    instructors = User.all.select { |u| u.is_instructor? }
    events = Event.all.select {|e| e.date.to_date == Time.now.to_date }
    Dependent.all.each do |d|
      unless rand(3) == 0
        Attendance.create(
          dependent_id: d.athlete_id,
          instructor_id: instructors.sample.id,
          event_id: events.sample.id,
          type_of_charge: (rand(3) == 0 ? "Cash" : "Credits")
        )
        puts "#{d.full_name} attended class!"
      end
    end
  end

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
