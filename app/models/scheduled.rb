class Scheduled < ActiveRecord::Base

  def self.send_class_text
    Subscription.all.each do |subscriber|
      Event.where(token: subscriber.event_id).select { |e| e.date.to_date == Time.now.to_date }.each do |event|
        num = User.find(subscriber.user_id).phone_number
        msg = "Hope to see you at our #{event.city} #{event.class_name.capitalize} class today at#{event.date.strftime('%l:%M')}!"
        ::SmsMailerWorker.perform_async(msg, num)
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
    User.find_by_first_name("Justin").update(bio:
      "After painfully discovering that he had gotten fat, Justin came to the realization that he needed to do something extreme to keep up with his five active boys. Four years ago Justin began his Parkour experience. Having several businesses, he decided to create structure to the Utah Parkour scene. With the help of others it has grown into what it is today. What you may not know about Justin is that he loves to fly airplanes and practice Yoga. Obviously not at the same time."
    )
    User.find_by_first_name("Rocco").update(bio:
      "Rocco is a long time Parkour and FreeRunning enthusiast and excited about ParkourUtah.com. This site is his creation. Having suffered an injury related to FreeRunning in the past, he has never lost his love for the sport. What may catch you off-guard is that he is from South Africa and loves riding motorcycles. But those aren’t the surprises, somehow over the years he got the nickname Zoro. With one R. We will let your mind wander about how that all came to be."
    )
    User.find_by_first_name("Jadon").update(bio:
      "JD is intense! His movement is profound. Having no indoor training available he contributes his ability to \"go big\" on having to develop a no fear attitude. He loves to perfect his moves and focus on flow and control. With 6 years of Parkour, it is his passion and love. 360° dives, 360° fronts, and one-handed push gainers are his favorite moves. Ask JD to sign his name with both hands... He is ambidextrous!"
    )
    User.find_by_first_name("William").update(bio:
      "Scott is a passionate and committed Parkour instructor. His love for the sport started in 2011 and has focused on Flow with a heavy emphasis on precision. His favorite move is a Russian front flip. Scott has a unique interest- he has a deep love for 50’s-70’s Folk Music. Don’t be surprised to hear singing while he is bouncing off the walls."
    )
    User.find_by_first_name("Stephen").update(bio:
      "Doing Parkour for three years and being A.D.A.P.T. certified, Parkour is life for Stephen. He is a big believer in the purist style of Parkour and loves the speed vault. Don’t let his height scare you. He is a little kid inside, and a great instructor. In fact, the kid is very much alive inside of him. He still loves 90’s dance music and isn’t afraid to roll with the windows down to technotronic. Pump up the Jam!!"
    )
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

end
