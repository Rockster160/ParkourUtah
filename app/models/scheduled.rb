class Scheduled < ActiveRecord::Base

  def self.send_text(num)
    ::SmsMailerWorker.perform_async("Class tonight!", ['3852599640'])
  end

  def self.send_summary(days)
    summary = {}
    payment = {}

    (0..(days - 1)).each do |day|
      classes = {}
      daily_payment = {}
      Event.select {|e| e.date.to_date == (Time.now - day.days).to_date}.each do |event|
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
        end
        instructors.each do |instructor|
          pay = instructor[1]["pay"] < 15 ? 15 : instructor[1]["pay"]
          instructor[1]["pay"] = pay
          payment[instructor[0]] ||= 0
          payment[instructor[0]] += pay
        end
        summary["#{(Time.now - day.days).to_date.strftime("%A %B %-d, %Y")}"] ||= {}
        summary["#{(Time.now - day.days).to_date.strftime("%A %B %-d, %Y")}"]["#{event.class_name.capitalize} - #{event.city} - #{event.date.strftime('%l:%M%p')}"] = instructors
      end
    end

    total_summary = [summary, payment]

    ::SummaryMailerWorker.perform_async(total_summary)
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
