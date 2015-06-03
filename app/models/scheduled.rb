class Scheduled < ActiveRecord::Base

  def self.send_class_text
    Subscription.all.each do |subscriber|
      user = subscriber.user
      Event.where(token: subscriber.token).select { |e| e.date.to_date == Time.now.to_date && e.date.hour == (Time.now + 2.hours).hour }.each do |event|
        if user.notifications.text_class_reminder
          num = user.phone_number
          if num.length == 10
            msg = "Hope to see you at our #{event.class_name.capitalize} class today at #{nil_padded_time(event.date.strftime('%l:%M'))}!"
            ::SmsMailerWorker.perform_async(num, msg)
          end
        end
        if user.notifications.email_class_reminder
          ::ClassReminderMailerWorker.perform_async(user.id, "Hope to see you at our #{event.class_name.capitalize} class today at #{nil_padded_time(event.date.strftime('%l:%M'))}!")
        end
      end
    end
  end

  def self.nil_padded_time(time)
    (time[0] == " " ? "" : time[0]) + time[1..4]
  end

  def self.send_test_text
    if Rails.env == "production"
      ::SmsMailerWorker.perform_async('3852599640', "This is a test from Parkour Utah in Production!")
    else
      ::SmsMailerWorker.perform_async('3852599640', "This is a test from Parkour Utah!")
    end
  end

  def self.send_summary(days)
    summary = {}
    payment = {}

    (0..(days - 1)).each do |day|
      events = Event.select {|e| e.date.to_date == (Time.now - day.days).to_date}
      special = Attendance.select do |attendance|
        (attendance.created_at - 7.hours).to_date == (Time.now - day.days).to_date && attendance.event_id == 1
      end.map {|attendance| attendance.event} - [[]]
      events += special if special.any?
      events.each do |event|
        instructors = {}
        return if event == []
        unless event.attendances.count == 0
          event.attendances.each do |attendance|
            instructor = User.find(attendance.user_id)
            athlete = Dependent.where(athlete_id: attendance.dependent_id).first

            instructors[instructor.full_name] ||= {}
            instructors[instructor.full_name]["students"] ||= []
            instructors[instructor.full_name]["pay"] ||= 0

            instructors[instructor.full_name]["students"] << "#{athlete.full_name} - #{attendance.type_of_charge}"
            pay = event.class_name == "Test" ? 15 : instructor.payment_multiplier
            instructors[instructor.full_name]["pay"] += pay

            attendance.sent!
          end
        else
          instructors[event.host] ||= {}
          instructors[event.host]["students"] = ["None"]
          instructors[event.host]["pay"] = 15
        end
        instructors.each do |instructor|
          pay = instructor[1]["pay"] < 15 ? 15 : instructor[1]["pay"]
          instructor[1]["pay"] = pay
          payment[instructor[0]] ||= 0
          payment[instructor[0]] += pay
        end
        summary["#{(Time.now - day.days).to_date.strftime("%A %B %-d, %Y")}"] ||= {}
        if event.class_name == "Test"
          summary["#{(Time.now - day.days).to_date.strftime("%A %B %-d, %Y")}"]["Private Class"] = instructors
        else
          summary["#{(Time.now - day.days).to_date.strftime("%A %B %-d, %Y")}"]["#{event.class_name.capitalize} - #{event.city} - #{event.date.strftime('%l:%M%p')}"] = instructors
        end
      end
    end

    total_summary = [summary, payment]

    ::SummaryMailerWorker.perform_async(total_summary)
  end

  def self.attend_random_classes(days=1)
    instructors = User.instructors.shuffle
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

  def self.monthly_subscription_charges
    count = 0
    User.every do |user|
      if !(user.has_unlimited_access?) && user.stripe_subscription? && user.stripe_id
        monthly_subscription = LineItem.where(is_subscription: true).first
        count += 1
        Stripe.api_key = ENV['PKUT_STRIPE_SECRET_KEY']
        charge = Stripe::Charge.create(
          :amount   => user.subscription_cost,
          :currency => "usd",
          :customer => user.stripe_id
        )
        if !(charge) || charge.status == "succeeded"
          SmsMailerWorker.perform_async('3852599640', "Successfully updated Subscription for #{user.email}.")
          if Rails.env == "production"
            # SubscriptionUpdatedMailerWorker.perform_async(user, user.email)
            # SubscriptionUpdatedMailerWorker.perform_async(user, "")
          end
          user.unlimited_subscriptions.create
        else
          SmsMailerWorker.perform_async('3852599640', "There was an issue updating the subscription for #{user.email}.")
        end
      end
    end
    SmsMailerWorker.perform_async('3852599640', "Tick : #{count}") if count > 0
  end

  def self.waiver_checks
    Dependent.all.each do |athlete|
      user = athlete.user
      if athlete.waiver.exp_date.to_date == (Time.now + 1.week).to_date
        if user.notifications.email_waiver_expiring
          ::ExpiringWaiverMailerWorker.perform_async(athlete.id)
        end
        if user.notifications.text_waiver_expiring
          ::SmsMailerWorker.perform_async('user.phone_number', "The waiver belonging to #{athlete.full_name} is no longer active as of #{athlete.waiver.exp_date.strftime('%B %e')}. Head up to ParkourUtah.com to get it renewed!")
        end
      end
    end
  end

  def self.reset_city_colors
    Event.all.to_a.group_by { |event| event.city }.keys.each_with_index do |city, pos|
      Event.set_city_color(city, Event.colors.keys[pos])
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

  def self.create_subscription_line_item
    LineItem.create(
      title: "Monthly Subscription",
      description: 'This is a recurring transaction. Your account will be charged automatically unless you unsubscribe via the Notifications button on your Profile. This allows your students to have unlimited access to classes for 1 month.',
      taxable: false,
      cost_in_pennies: 5000,
      is_subscription: true,
      category: "Other"
    )
  end

end
