class Scheduled < ActiveRecord::Base

  def self.send_class_text
        binding.pry
    Subscription.all.each do |subscriber|
      Event.where(token: subscriber.event.token).select { |e| e.date.to_date == Time.now.to_date }.each do |event|
        num = subscriber.user.phone_number
        unless num == ""
          msg = "Hope to see you at our #{event.city} #{event.class_name.capitalize} class today at#{event.date.strftime('%l:%M')}!"
          ::SmsMailerWorker.perform_async(msg, num)
        end
      end
    end
  end

  def self.send_test_text
    if Rails.env == "production"
      ::SmsMailerWorker.perform_async("This is a test from Parkour Utah in Production!", '3852599640')
    else
      ::SmsMailerWorker.perform_async("This is a test from Parkour Utah!", '3852599640')
    end
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
          instructor = User.find(a.user_id)
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

  def self.attend_random_classes(days=1)
    instructors = User.all.select { |u| u.is_instructor? }
    days.times do |day|
      events = Event.all.select {|e| e.date.to_date == (Time.now - day.days).to_date }
      if events.any?
        Dependent.all.each do |d|
          unless rand(3) == 0
            Attendance.create(
              dependent_id: d.athlete_id,
              user_id: instructors.sample.id,
              event_id: events.sample.id,
              type_of_charge: (rand(3) == 0 ? "Cash" : "Credits")
            )
            puts "#{d.full_name} attended class!"
          end
        end
      end
    end
  end

  def self.seed
    # self.update_users
    self.reset_classes
    self.reset_store
  end

  def self.update_users
  end

  def self.reset_classes
    self.clear_classes
    self.create_classes
  end

  def self.reset_store
    self.clear_store
    self.create_store
  end

  def self.clear_classes
    self.clear_subscriptions
    puts "Removing all events"
    Event.all.each do |e|
      e.destroy
      print "\e[31m-\e[0m"
    end
    puts "\nEvents removed"
  end

  def self.clear_subscriptions
    puts "Removing all Subscriptions"
    Subscription.all.each do |s|
      s.destroy
      print "\e[31m-\e[0m"
    end
    puts "\nSubscriptions removed"
  end

  def self.create_classes
  end

  def self.clear_store
    puts "Removing all store items"
    LineItem.all.each do |l|
      l.destroy
      print "\e[31m-\e[0m"
    end
    puts "\nLine Items removed"
  end

  def self.create_store
  end

  def self.update_store
  end

end
