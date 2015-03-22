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

  def self.temp_seed
    reset_subscriptions
    reset_classes
    update_users
  end

  def update_users
    instructors = %w( Justin Ryan Brianna Rocco Aaron Jadon Tony William Marcos Stephen Zeter )
    bios = [
      "After painfully discovering that he had gotten fat, Justin had come to the knowledge he needed to do something extreme to keep up with his five active boys. Four years ago Justin began his Parkour experience. Having several businesses he decided to create structure to the Utah Parkour scene. With the help of others it has grown and is what it is today. What you may not know about Justin is that he loves to fly airplanes, and practice Yoga. Obviously not at the same time.",
      "Passion, Desire, and commitment to the sport of Parkour are what describes Ryan. After 10 years of doing Parkour and introducing countless others to the sport, Ryan loves helping others learn and perfect Parkour. Running dive rolls are Ryan's signature move. With all his experience with martial arts and Parkour, Ryan has been able to choreograph many fight scenes for film and theater. For extra credit Ryan enjoys making unique dishes in the kitchen. Ryan's favorite meal is anything with extra garlic.",
      "Amazing is an understatement when it comes to describing Bri. She has truly been a fundamental element in getting Parkourutah where it is. She has worked tirelessly to make sure all questions are answered and all things are in there place. Although you may not see her often, she is still there working to make sure that classes and events happen. Bri may shock you when you discover she not only is the mother of a beautiful daughter, she also knows how to juggle chainsaws while riding a unicorn.",
      "Rocco is a long time Parkour enthusiast and excited about ParkourUtah.com. This site is his creation. Having suffered an injury related to parkour, he has never lost his love for the sport. What would surprise all people is that he is from South Africa and loves riding motorcycles. But those aren’t the surprises, somehow over the years he got a nickname of Zorro. We will let your mind wander about how that all came to be. ",
      "Aaron is an all around good guy. He has lots of skills behind the camera, and behind the computer to make us all look better than we really are. He loves his job doing this kind of work. He has a unique trait or two. Many kids have mistaken him to be Peter Parker from Spiderman. He openly admits he is a nerd, never caught a fish, plays fat-man football, and used to be a ballroom dancer. Despite all these things, he still can cook on a 15 inch grill in the backyard where he can reinstate his manhood. ",
      "",
      "Tony has been an instructor for parkour for a great length of time. He finds himself as a “in between” Parkour and Freerunning style. If you really want to debate that there is a difference. His opinion, is that all moves are an equally awesome expression of movement. Tony has a distinct eye for fashion and loves to express himself through style and appearance. Don’t ask him to cook for you though, he recently dropped out of culinary school. ",
      "Scott is a passionate and committed parkour instructor. His love for the sport started in 2011 and has focused on Flow with a heavy emphasis on precision. His favorite move is a Russian front flip. Scott has a unique interest, he has a deep love for 50’s-70’s Folk Music. Don’t be surprised to hear singing while he is bouncing of the walls.",
      "For obvious reasons you can see how “Shrimpy” got his name. Don’t let his size deceive you, every move from Marcos is huge. He loves to be fluid in his movements, and large on his jumps. Favorite moves includes the Dash and Italian Job. What will surprise you is that Marcos has been playing the piano since he was 5 and can play music by ear.",
      "Doing Parkour for three years and being Adapt certified, Parkour is life for Stephen. He is a big believer in the purist style of Parkour and loves the speed vault. Don’t let his height scare you. He is a little kid inside and is a great instructor. In fact the kid is very much alive inside of him, he still loves 90’s dance music and isn’t afraid to roll with the windows down to technotronic. Pump up the Jam!!  ",
      "Zeter loves parkour more than most. Parkour is like air for him. He has been at it for 6 years and loves everything about it. He loves flow/spin style of Parkour. His favorites are Rail Balance and Lazy Vaults. If you asked him what the craziest thing he has ever done was, he would have to think about it for a while. If there is something crazy to do, he has most likely done it. If he hasn’t, he will make sure to go out of his way to do it."
    ]
    stats = [
      "5'10\" 190 lbs",
      "5'6\" 175 lbs",
      "5'6\" <Invalid Request>",
      "5'10\" 180 lbs",
      "5'10\" 170 lbs",
      "'\"  lbs",
      "5'5\" 150 lbs",
      "5'6\" 164 lbs",
      "5'3\" 115 lbs",
      "6'2\" 195 lbs",
      "6'0\" 170 lbs"
    ]
    titles = [
      "Owner/Instructor",
      "Manager/Instructor",
      "Assistant",
      "Web Development/Instructor",
      "Photography/Cinematography",
      "Instructor",
      "Instructor",
      "Instructor",
      "Instructor",
      "Instructor",
      "Instructor"
    ]
    instructors.each_with_index do |instructor, pos|
      User.where(first_name: instructor).first
      User.update(
        bio: bios[pos],
        stats: stats[pos],
        title: titles[pos]
      )
    end
  end

  def clear_subscriptions
    puts "Removing all Subscriptions..."
    Subscription.all.each do |s|
      s.destroy
      print "."
    end
    puts "\n Subscriptions removed."
    puts "Removing all events..."
    Event.all.each do |e|
      e.destroy
      print "."
    end
    puts "\nEvents removed."
  end

  def reset_classes
  puts "Creating Events..."
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
      title: 'weekly Draper fundamentals',
      description: 'Our weekly Draper fundamentals class. Wear comfortable clothing that is easy to move in and a water bottle. Class runs for an hour and a half and involves moving all around the park. Make sure to bring your punch card or $12 via Credit Card for a single class. If you haven''t ever been before a WAIVER will need to be signed by you (if you\'re 18+) or a parent. If you have any questions about the class feel free to contact the teacher,
      Justin Spencer, via text or call 801-580-9274.',
      city: 'Draper',
      token: 1,
      address: '944 East Vestry Road',
      location_instructions: 'Draper Amphitheater',
      class_name: 'fundamentals'
    )
    print "."
    # Monday
    Event.create(
      date: DateTime.new(2015, 1, 5, 17, 30) + (t.weeks),
      host: 'Justin Spencer',
      title: 'weekly South Jordan fundamentals',
      description: 'Our weekly South Jordan fundamentals class. Wear comfortable clothing that is easy to move in and a water bottle. Class runs for an hour and a half and involves moving all around the park. Make sure to bring your punch card or $12 via Credit Card for a single class. If you haven''t ever been before a WAIVER will need to be signed by you (if you\'re 18+) or a parent. If you have any questions about the class feel free to contact the teacher,
      Justin Spencer, via text or call 801-580-9274.',
      city: 'South Jordan',
      token: 2,
      address: '10996 River Front Pkwy',
      location_instructions: 'South Jordan South Pavilion Park',
      class_name: 'fundamentals'
    )
    print "."

    # Tuesday
    Event.create(
      date: DateTime.new(2015, 1, 6, 16, 30) + (t.weeks),
      host: 'Ryan Sannar',
      title: 'weekly Orem fundamentals',
      description: 'Our weekly Orem fundamentals class. Wear comfortable clothing that is easy to move in and a water bottle. Class runs for an hour and a half and involves moving all around the park. Make sure to bring your punch card or $12 via Credit Card for a single class. If you haven''t ever been before a WAIVER will need to be signed by you (if you\'re 18+) or a parent. If you have any questions about the class feel free to contact the teacher,
      Ryan Sannar, via text or call 801-669-7743.',
      city: 'Orem',
      token: 3,
      address: '600 South State Street, Orem',
      location_instructions: 'Orem Scera Park',
      class_name: 'fundamentals'
    )
    print "."
    # Tuesday
    Event.create(
      date: DateTime.new(2015, 1, 6, 16, 30) + (t.weeks),
      host: 'Ryan Sannar',
      title: 'weekly Saratoga Springs fundamentals',
      description: 'Our weekly Saratoga Springs fundamentals class. Wear comfortable clothing that is easy to move in and a water bottle. Class runs for an hour and a half and involves moving all around the park. Make sure to bring your punch card or $12 via Credit Card for a single class. If you haven''t ever been before a WAIVER will need to be signed by you (if you\'re 18+) or a parent. If you have any questions about the class feel free to contact the teacher,
      Ryan Sannar, via text or call 801-669-7743.',
      city: 'Saratoga Springs',
      token: 4,
      address: 'Harvest Hills Park, 2104 North Providence Drive',
      location_instructions: 'Saratoga Springs Harvest Hills Park',
      class_name: 'fundamentals'
    )
    print "."
    # Tuesday
    Event.create(
      date: DateTime.new(2015, 1, 6, 17, 30) + (t.weeks),
      host: 'Justin Spencer',
      title: 'weekly West Jordan fundamentals',
      description: 'Our weekly West Jordan fundamentals class. Wear comfortable clothing that is easy to move in and a water bottle. Class runs for an hour and a half and involves moving all around the park. Make sure to bring your punch card or $12 via Credit Card for a single class. If you haven''t ever been before a WAIVER will need to be signed by you (if you\'re 18+) or a parent. If you have any questions about the class feel free to contact the teacher,
      Justin Spencer, via text or call 801-580-9274.',
      city: 'Saratoga Springs',
      token: 5,
      address: 'Veteran\'s Memorial Park',
      location_instructions: 'West Jordan Veteran\'s Memorial Park',
      class_name: 'fundamentals'
    )
    print "."

    # Wednesday
    Event.create(
      date: DateTime.new(2015, 1, 7, 16, 30) + (t.weeks),
      host: 'Ryan Sannar',
      title: 'weekly Sandy fundamentals',
      description: 'Our weekly Sandy fundamentals class. Wear comfortable clothing that is easy to move in and a water bottle. Class runs for an hour and a half and involves moving all around the park. Make sure to bring your punch card or $12 via Credit Card for a single class. If you haven''t ever been before a WAIVER will need to be signed by you (if you\'re 18+) or a parent. If you have any questions about the class feel free to contact the teacher,
      Ryan Sannar, via text or call 801-669-7743.',
      city: 'Sandy',
      token: 6,
      address: '1700 Siesta Drive',
      location_instructions: '',
      class_name: 'fundamentals'
    )
    print "."
    # Wednesday
    Event.create(
      date: DateTime.new(2015, 1, 7, 16, 30) + (t.weeks),
      host: 'Marcos Jones',
      title: 'first bi-weekly Vernal fundamentals',
      description: 'Our first bi-weekly Vernal fundamentals class. Wear comfortable clothing that is easy to move in and a water bottle. Class runs for an hour and a half and involves moving all around the park. Make sure to bring your punch card or $12 via Credit Card for a single class. If you haven''t ever been before a WAIVER will need to be signed by you (if you\'re 18+) or a parent. If you have any questions about the class feel free to contact the teacher,
      Marcos Jones, via text or call 435-612-0532.',
      city: 'Vernal',
      token: 7,
      address: 'Ashley Valley Community Park',
      location_instructions: '',
      class_name: 'fundamentals'
    )
    print "."
    # Wednesday
    Event.create(
      date: DateTime.new(2015, 1, 7, 17, 30) + (t.weeks),
      host: 'Justin Spencer',
      title: 'weekly Taylorsville fundamentals',
      description: 'Our weekly Taylorsville fundamentals class. Wear comfortable clothing that is easy to move in and a water bottle. Class runs for an hour and a half and involves moving all around the park. Make sure to bring your punch card or $12 via Credit Card for a single class. If you haven''t ever been before a WAIVER will need to be signed by you (if you\'re 18+) or a parent. If you have any questions about the class feel free to contact the teacher,
      Justin Spencer, via text or call 801-580-9274.',
      city: 'Salt Lake City',
      token: 8,
      address: '5100 S 2700 W, Salt Lake City, UT 84118',
      location_instructions: 'Taylorsville Valley Regional Park',
      class_name: 'fundamentals'
    )
    print "."

    # Thursday
    Event.create(
      date: DateTime.new(2015, 1, 1, 16, 30) + (t.weeks),
      host: 'Scott May',
      title: 'weekly Provo fundamentals',
      description: 'Our weekly Provo fundamentals class. Wear comfortable clothing that is easy to move in and a water bottle. Class runs for an hour and a half and involves moving all around the park. Make sure to bring your punch card or $12 via Credit Card for a single class. If you haven''t ever been before a WAIVER will need to be signed by you (if you\'re 18+) or a parent. If you have any questions about the class feel free to contact the teacher,
      Scott May, via text or call 435-549-0303.',
      city: 'Provo',
      token: 9,
      address: 'Kiwanis Park Tennis Courts, 8200 North 1100 East',
      location_instructions: '',
      class_name: 'fundamentals'
    )
    print "."
    # Thursday
    Event.create(
      date: DateTime.new(2015, 1, 1, 16, 30) + (t.weeks),
      host: 'Justin Spencer',
      title: 'weekly Liberty Park fundamentals',
      description: 'Our weekly Liberty Park fundamentals class. Wear comfortable clothing that is easy to move in and a water bottle. Class runs for an hour and a half and involves moving all around the park. Make sure to bring your punch card or $12 via Credit Card for a single class. If you haven''t ever been before a WAIVER will need to be signed by you (if you\'re 18+) or a parent. If you have any questions about the class feel free to contact the teacher,
      Justin Spencer, via text or call 801-580-9274.',
      city: 'Salt Lake City',
      token: 10,
      address: 'Liberty Park, 600 East 900 South',
      location_instructions: '',
      class_name: 'fundamentals'
    )
    print "."
    # Thursday
    Event.create(
      date: DateTime.new(2015, 1, 1, 17, 30) + (t.weeks),
      host: 'Justin Spencer',
      title: 'weekly Herriman fundamentals',
      description: 'Our weekly Herriman fundamentals class. Wear comfortable clothing that is easy to move in and a water bottle. Class runs for an hour and a half and involves moving all around the park. Make sure to bring your punch card or $12 via Credit Card for a single class. If you haven''t ever been before a WAIVER will need to be signed by you (if you\'re 18+) or a parent. If you have any questions about the class feel free to contact the teacher,
      Justin Spencer, via text or call 801-580-9274.',
      city: 'Herriman',
      token: 12,
      address: '13850 W Rosecrest Rd Herriman, UT',
      location_instructions: 'Herriman Rosecrest Park',
      class_name: 'fundamentals'
    )
    print "."

    # Friday
    # Event.create(
    #   date: DateTime.new(2015, 1, 2, 16, 30) + (t.weeks),
    #   host: 'Ryan Sannar'
    #   title: 'weekly Draper fundamentals',
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
      host: 'Marcos Jones',
      title: 'weekly Ogden fundamentals',
      description: 'Our weekly Ogden fundamentals class. Wear comfortable clothing that is easy to move in and a water bottle. Class runs for an hour and a half and involves moving all around the park. Make sure to bring your punch card or $12 via Credit Card for a single class. If you haven''t ever been before a WAIVER will need to be signed by you (if you\'re 18+) or a parent. If you have any questions about the class feel free to contact the teacher,
      Zeter Raimondo, via text or call 801-620-0672.',
      city: 'Ogden',
      token: 13,
      address: 'City Hall Park, Ogden, UT 84401',
      location_instructions: 'Ogden City Hall',
      class_name: 'fundamentals'
    )
    print "."
    # Saturday
    Event.create(
      date: DateTime.new(2015, 1, 3, 11, 00) + (t.weeks),
      host: 'Tony Mungiguerra',
      title: 'weekly Springville fundamentals',
      description: 'Our weekly Springville fundamentals class. Wear comfortable clothing that is easy to move in and a water bottle. Class runs for an hour and a half and involves moving all around the park. Make sure to bring your punch card or $12 via Credit Card for a single class. If you haven''t ever been before a WAIVER will need to be signed by you (if you\'re 18+) or a parent. If you have any questions about the class feel free to contact the teacher,
      Tony Mungiguerra, via text or call 818-442-4404.',
      city: 'Springville',
      token: 14,
      address: '110 S Main St Springville, UT',
      location_instructions: 'Outside Springville Civic Center',
      class_name: 'fundamentals'
    )
    print "."
    # Saturday
    Event.create(
      date: DateTime.new(2015, 1, 3, 16, 00) + (t.weeks),
      host: 'Marcos Jones',
      title: 'second bi-weeky Vernal fundamentals',
      description: 'Our second bi-weeky Vernal fundamentals class. Wear comfortable clothing that is easy to move in and a water bottle. Class runs for an hour and a half and involves moving all around the park. Make sure to bring your punch card or $12 via Credit Card for a single class. If you haven''t ever been before a WAIVER will need to be signed by you (if you\'re 18+) or a parent. If you have any questions about the class feel free to contact the teacher,
      Marcos Jones, via text or call 435-612-0532.',
      city: 'Vernal',
      token: 15,
      address: 'Ashley Valley Community Park',
      location_instructions: 'Ashley Valley Community Park',
      class_name: 'fundamentals'
    )
    print "."
  end
  puts "\nCompleted all events."
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
