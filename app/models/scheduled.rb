class Scheduled < ActiveRecord::Base

  def self.send_text
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
    puts "Creating Events"
    Event.create(
      date: DateTime.new(1990),
      host: 'Expert',
      description: 'This is the expert class. It is by invite only.',
      city: 'Provo',
      token: 0,
      address: 'To be specific',
      location_instructions: '',
      class_name: 'Test'
    )
    puts "Created 1on1 event."
    50.times do |t|
      # Monday
      Event.create(
        date: DateTime.new(2015, 1, 5, 16, 30) + (t.weeks),
        host: 'Justin Spencer',
        title: 'Draper fundamentals',
        description: 'Our weekly Draper fundamentals class. Wear comfortable clothing that is easy to move in and a water bottle. Class runs for an hour and a half and involves moving all around the park. Make sure to bring your punch card or $12 via Credit Card for a single class. If you haven''t ever been before a WAIVER will need to be signed by you (if you\'re 18+) or a parent. If you have any questions about the class feel free to contact the teacher,
        Justin Spencer, via text or call 801-580-9274.',
        city: 'Draper',
        token: 1,
        address: '944 East Vestry Road',
        location_instructions: 'Draper Amphitheater',
        class_name: 'fundamentals'
      )
      print "\e[32m.\e[0m"
      # Monday
      Event.create(
        date: DateTime.new(2015, 1, 5, 17, 30) + (t.weeks),
        host: 'Justin Spencer',
        title: 'Jordan fundamentals',
        description: 'Our weekly South Jordan fundamentals class. Wear comfortable clothing that is easy to move in and a water bottle. Class runs for an hour and a half and involves moving all around the park. Make sure to bring your punch card or $12 via Credit Card for a single class. If you haven''t ever been before a WAIVER will need to be signed by you (if you\'re 18+) or a parent. If you have any questions about the class feel free to contact the teacher,
        Justin Spencer, via text or call 801-580-9274.',
        city: 'South Jordan',
        token: 2,
        address: '10996 River Front Pkwy',
        location_instructions: 'South Jordan South Pavilion Park',
        class_name: 'fundamentals'
      )
      print "\e[32m.\e[0m"

      # Tuesday
      Event.create(
        date: DateTime.new(2015, 1, 6, 16, 30) + (t.weeks),
        host: 'Ryan Sannar',
        title: 'Orem fundamentals',
        description: 'Our weekly Orem fundamentals class. Wear comfortable clothing that is easy to move in and a water bottle. Class runs for an hour and a half and involves moving all around the park. Make sure to bring your punch card or $12 via Credit Card for a single class. If you haven''t ever been before a WAIVER will need to be signed by you (if you\'re 18+) or a parent. If you have any questions about the class feel free to contact the teacher,
        Ryan Sannar, via text or call 801-669-7743.',
        city: 'Orem',
        token: 3,
        address: '600 South State Street, Orem',
        location_instructions: 'Orem Scera Park',
        class_name: 'fundamentals'
      )
      print "\e[32m.\e[0m"
      # Tuesday
      Event.create(
        date: DateTime.new(2015, 1, 6, 16, 30) + (t.weeks),
        host: 'Ryan Sannar',
        title: 'Springs fundamentals',
        description: 'Our weekly Saratoga Springs fundamentals class. Wear comfortable clothing that is easy to move in and a water bottle. Class runs for an hour and a half and involves moving all around the park. Make sure to bring your punch card or $12 via Credit Card for a single class. If you haven''t ever been before a WAIVER will need to be signed by you (if you\'re 18+) or a parent. If you have any questions about the class feel free to contact the teacher,
        Ryan Sannar, via text or call 801-669-7743.',
        city: 'Saratoga Springs',
        token: 4,
        address: 'Harvest Hills Park, 2104 North Providence Drive',
        location_instructions: 'Saratoga Springs Harvest Hills Park',
        class_name: 'fundamentals'
      )
      print "\e[32m.\e[0m"
      # Tuesday
      Event.create(
        date: DateTime.new(2015, 1, 6, 17, 30) + (t.weeks),
        host: 'Justin Spencer',
        title: 'Jordan fundamentals',
        description: 'Our weekly West Jordan fundamentals class. Wear comfortable clothing that is easy to move in and a water bottle. Class runs for an hour and a half and involves moving all around the park. Make sure to bring your punch card or $12 via Credit Card for a single class. If you haven''t ever been before a WAIVER will need to be signed by you (if you\'re 18+) or a parent. If you have any questions about the class feel free to contact the teacher,
        Justin Spencer, via text or call 801-580-9274.',
        city: 'Saratoga Springs',
        token: 5,
        address: 'Veteran\'s Memorial Park',
        location_instructions: 'West Jordan Veteran\'s Memorial Park',
        class_name: 'fundamentals'
      )
      print "\e[32m.\e[0m"

      # Wednesday
      Event.create(
        date: DateTime.new(2015, 1, 7, 16, 30) + (t.weeks),
        host: 'Ryan Sannar',
        title: 'Sandy fundamentals',
        description: 'Our weekly Sandy fundamentals class. Wear comfortable clothing that is easy to move in and a water bottle. Class runs for an hour and a half and involves moving all around the park. Make sure to bring your punch card or $12 via Credit Card for a single class. If you haven''t ever been before a WAIVER will need to be signed by you (if you\'re 18+) or a parent. If you have any questions about the class feel free to contact the teacher,
        Ryan Sannar, via text or call 801-669-7743.',
        city: 'Sandy',
        token: 6,
        address: '1700 Siesta Drive',
        location_instructions: '',
        class_name: 'fundamentals'
      )
      print "\e[32m.\e[0m"
      # Wednesday
      Event.create(
        date: DateTime.new(2015, 1, 7, 16, 30) + (t.weeks),
        host: 'Marcos Jones',
        title: 'Vernal fundamentals',
        description: 'Our first bi-weekly Vernal fundamentals class. Wear comfortable clothing that is easy to move in and a water bottle. Class runs for an hour and a half and involves moving all around the park. Make sure to bring your punch card or $12 via Credit Card for a single class. If you haven''t ever been before a WAIVER will need to be signed by you (if you\'re 18+) or a parent. If you have any questions about the class feel free to contact the teacher,
        Marcos Jones, via text or call 435-612-0532.',
        city: 'Vernal',
        token: 7,
        address: 'Ashley Valley Community Park',
        location_instructions: '',
        class_name: 'fundamentals'
      )
      print "\e[32m.\e[0m"
      # Wednesday
      Event.create(
        date: DateTime.new(2015, 1, 7, 17, 30) + (t.weeks),
        host: 'Justin Spencer',
        title: 'Taylorsville fundamentals',
        description: 'Our weekly Taylorsville fundamentals class. Wear comfortable clothing that is easy to move in and a water bottle. Class runs for an hour and a half and involves moving all around the park. Make sure to bring your punch card or $12 via Credit Card for a single class. If you haven''t ever been before a WAIVER will need to be signed by you (if you\'re 18+) or a parent. If you have any questions about the class feel free to contact the teacher,
        Justin Spencer, via text or call 801-580-9274.',
        city: 'Salt Lake City',
        token: 8,
        address: '5100 S 2700 W, Salt Lake City, UT 84118',
        location_instructions: 'Taylorsville Valley Regional Park',
        class_name: 'fundamentals'
      )
      print "\e[32m.\e[0m"

      # Thursday
      Event.create(
        date: DateTime.new(2015, 1, 1, 16, 30) + (t.weeks),
        host: 'Scott May',
        title: 'Provo fundamentals',
        description: 'Our weekly Provo fundamentals class. Wear comfortable clothing that is easy to move in and a water bottle. Class runs for an hour and a half and involves moving all around the park. Make sure to bring your punch card or $12 via Credit Card for a single class. If you haven''t ever been before a WAIVER will need to be signed by you (if you\'re 18+) or a parent. If you have any questions about the class feel free to contact the teacher,
        Scott May, via text or call 435-549-0303.',
        city: 'Provo',
        token: 9,
        address: 'Kiwanis Park Tennis Courts, 8200 North 1100 East',
        location_instructions: '',
        class_name: 'fundamentals'
      )
      print "\e[32m.\e[0m"
      # Thursday
      Event.create(
        date: DateTime.new(2015, 1, 1, 16, 30) + (t.weeks),
        host: 'Justin Spencer',
        title: 'Park fundamentals',
        description: 'Our weekly Liberty Park fundamentals class. Wear comfortable clothing that is easy to move in and a water bottle. Class runs for an hour and a half and involves moving all around the park. Make sure to bring your punch card or $12 via Credit Card for a single class. If you haven''t ever been before a WAIVER will need to be signed by you (if you\'re 18+) or a parent. If you have any questions about the class feel free to contact the teacher,
        Justin Spencer, via text or call 801-580-9274.',
        city: 'Salt Lake City',
        token: 10,
        address: 'Liberty Park, 600 East 900 South',
        location_instructions: '',
        class_name: 'fundamentals'
      )
      print "\e[32m.\e[0m"
      # Thursday
      Event.create(
        date: DateTime.new(2015, 1, 1, 17, 30) + (t.weeks),
        host: 'Justin Spencer',
        title: 'Herriman fundamentals',
        description: 'Our weekly Herriman fundamentals class. Wear comfortable clothing that is easy to move in and a water bottle. Class runs for an hour and a half and involves moving all around the park. Make sure to bring your punch card or $12 via Credit Card for a single class. If you haven''t ever been before a WAIVER will need to be signed by you (if you\'re 18+) or a parent. If you have any questions about the class feel free to contact the teacher,
        Justin Spencer, via text or call 801-580-9274.',
        city: 'Herriman',
        token: 12,
        address: '13850 W Rosecrest Rd Herriman, UT',
        location_instructions: 'Herriman Rosecrest Park',
        class_name: 'fundamentals'
      )
      print "\e[32m.\e[0m"

      # Friday
      # Event.create(
      #   date: DateTime.new(2015, 1, 2, 16, 30) + (t.weeks),
      #   host: 'Ryan Sannar'
      #   Draper fundamentals',
      #   description: 'Our second bi-weekly Sandy fundamentals class. Wear comfortable clothing that is easy to move in and a water bottle. Class runs for an hour and a half and involves moving all around the park. Make sure to bring your punch card or $12 via Credit Card for a single class. If you haven''t ever been before a WAIVER will need to be signed by you (if you\'re 18+) or a parent. If you have any questions about the class feel free to contact the teacher,
      #   Ryan Sannar, via text or call 801-669-7743.',
      #   city: 'Sandy',
      #   token: 3,
      #   address: 'Crestwood Park 1700 Siesta Drive',
      #   location_instructions: '',
      #   class_name: 'fundamentals'
      # )

      # Saturday
      Event.create(
        date: DateTime.new(2015, 1, 3, 11, 00) + (t.weeks),
        host: 'Zeter Raimondo',
        title: 'Ogden fundamentals',
        description: 'Our weekly Ogden fundamentals class. Wear comfortable clothing that is easy to move in and a water bottle. Class runs for an hour and a half and involves moving all around the park. Make sure to bring your punch card or $12 via Credit Card for a single class. If you haven''t ever been before a WAIVER will need to be signed by you (if you\'re 18+) or a parent. If you have any questions about the class feel free to contact the teacher,
        Zeter Raimondo, via text or call 801-620-0672.',
        city: 'Ogden',
        token: 13,
        address: 'City Hall Park, Ogden, UT 84401',
        location_instructions: 'Ogden City Hall',
        class_name: 'fundamentals'
      )
      print "\e[32m.\e[0m"
      # Saturday
      Event.create(
        date: DateTime.new(2015, 1, 3, 11, 00) + (t.weeks),
        host: 'Tony Mungiguerra',
        title: 'Springville fundamentals',
        description: 'Our weekly Springville fundamentals class. Wear comfortable clothing that is easy to move in and a water bottle. Class runs for an hour and a half and involves moving all around the park. Make sure to bring your punch card or $12 via Credit Card for a single class. If you haven''t ever been before a WAIVER will need to be signed by you (if you\'re 18+) or a parent. If you have any questions about the class feel free to contact the teacher,
        Tony Mungiguerra, via text or call 818-442-4404.',
        city: 'Springville',
        token: 14,
        address: '110 S Main St Springville, UT',
        location_instructions: 'Outside Springville Civic Center',
        class_name: 'fundamentals'
      )
      # Saturday
      Event.create(
        date: DateTime.new(2015, 1, 3, 16, 00) + (t.weeks),
        host: 'Marcos Jones',
        title: 'Vernal fundamentals',
        description: 'Our second bi-weeky Vernal fundamentals class. Wear comfortable clothing that is easy to move in and a water bottle. Class runs for an hour and a half and involves moving all around the park. Make sure to bring your punch card or $12 via Credit Card for a single class. If you haven''t ever been before a WAIVER will need to be signed by you (if you\'re 18+) or a parent. If you have any questions about the class feel free to contact the teacher,
        Marcos Jones, via text or call 435-612-0532.',
        city: 'Vernal',
        token: 15,
        address: 'Ashley Valley Community Park',
        location_instructions: 'Ashley Valley Community Park',
        class_name: 'fundamentals'
      )
      print "\e[32m.\e[0m"
    end
    puts "\nCompleted all events"
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
    puts "Adding new line items"
    LineItem.create(
      title: "Class Admission",
      description: "Purchasing this item will add credits to your account that are good for 1 class for 1 student. Students must have a Waiver filled out before attending class.",
      cost_in_pennies: 1200,
      item_order: 1,
      category: "Class"
    )
    print "\e[32m.\e[0m"
    LineItem.create(
      title: "Expert Class Tryout",
      description: "Expert Tryouts are by invite ONLY. Purchasing this item will add credits to your account that are good for 1 tryout for 1 student. Instructors will set up a time and day with the student in order to schedule a 1 on 1 tryout.",
      cost_in_pennies: 3500,
      item_order: 2,
      category: "Class"
    )
    print "\e[32m.\e[0m"
    LineItem.create(
      title: "Scout Package",
      hidden: true,
      cost_in_pennies: 2000,
      category: "Class"
    )
    print "\e[32m.\e[0m"
    LineItem.create(
      title: "Trial Class",
      hidden: true,
      cost_in_pennies: 0,
      category: "Class"
    )
    print "\e[32m.\e[0m"
    puts "\nStore reset complete."
  end

end
