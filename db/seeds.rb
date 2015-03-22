# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)
cities = %w[ Sandy Draper Salt\ Lake\ City Lehi Orem Provo Murray Holladay South\ Jordan ]
classes = %w[ beginner intermediate conditioning jam tricking ]

instructor_firsts = %w( Justin Ryan Brianna Rocco Aaron Jadon Tony William Marcos Stephen Zeter )
instructor_nicks = ["Captain Awesome", "", "", "Zoro", "", "JD", "", "Scott", "Shrimpy", "", ""]
instructor_lasts = %w( Spencer Sannar Midas Nicholls Cornia Erwin Mungiguerra May Jones Lanteri Raimondo )
bios = [
  "After painfully discovering that he had gotten fat, Justin had come to the realization that he needed to do something extreme to keep up with his five active boys. Four years ago Justin began his Parkour experience. Having several businesses, he decided to create structure to the Utah Parkour scene. With the help of others it has grown into what it is today. What you may not know about Justin is that he loves to fly airplanes and practice Yoga. Obviously not at the same time.",
  "Passion, Desire, and commitment to the sport of Parkour are what describes Ryan. After 10 years of doing Parkour and introducing countless others to the sport, Ryan has found a love for helping others learn and perfect Parkour. Running dive rolls are Ryan's signature move. With all his experience with martial arts and Parkour, Ryan has been able to choreograph many fight scenes for film and theater. For extra credit Ryan enjoys making unique dishes in the kitchen. Ryan's favorite meal is anything with extra garlic.",
  "Amazing is an understatement when it comes to describing Bri. She has truly been a fundamental element in getting ParkourUtah to where it is today. She has worked tirelessly to make sure all questions are answered and all things are in their place. Although you may not see her often, she is always in the background working to make sure that classes and events happen. Bri may shock you when you discover she not only is the mother of a beautiful daughter, she also knows how to juggle chainsaws while riding a unicorn.",
  "Rocco is a long time Parkour and FreeRunning enthusiast and excited about ParkourUtah.com. This site is his creation. Having suffered an injury related to FreeRunning in the past, he has never lost his love for the sport. What may catch you off guard is that he is from South Africa and loves riding motorcycles. But those aren’t the surprises, somehow over the years he got the nickname Zoro. We will let your mind wander about how that all came to be.",
  "Aaron is an all around good guy. He has lots of skills behind the camera and behind the computer to make us all look better than we really are. He loves his job doing this kind of work. Many kids have mistaken him to be Peter Parker from Spiderman. He openly admits he is a nerd, never caught a fish, plays fat-man football, and used to be a ballroom dancer. Despite all these things, he still can cook on a 15 inch grill in the backyard where he can reinstate his manhood.",
  "",
  "Tony has been an instructor for Parkour for a great length of time. He finds himself as an \"in between\" Parkour and FreeRunning style. If you really want to debate that there is a difference; his opinion:  all moves are an equally awesome expression of movement. Tony has a distinct eye for fashion and loves to express himself through style and appearance. Don’t ask him to cook for you though, he recently dropped out of culinary school.",
  "Scott is a passionate and committed Parkour instructor. His love for the sport started in 2011 and has focused on Flow with a heavy emphasis on precision. His favorite move is a Russian front flip. Scott has a unique interest- he has a deep love for 50’s-70’s Folk Music. Don’t be surprised to hear singing while he is bouncing of the walls.",
  "For obvious reasons you can see how \"Shrimpy\" got his name. Don’t let his size deceive you, every move from Marcos is huge. He loves to be fluid in his movements and large on his jumps. Favorite moves include the Dash vault and Italian Job. What will surprise you is that Marcos has been playing the piano since he was 5 and can play music by ear.",
  "Doing Parkour for three years and being Adapt certified, Parkour is life for Stephen. He is a big believer in the purist style of Parkour and loves the speed vault. Don’t let his height scare you. He is a little kid inside and is a great instructor. In fact, the kid is very much alive inside of him. He still loves 90’s dance music and isn’t afraid to roll with the windows down to technotronic. Pump up the Jam!!",
  "Zeter loves Parkour more than most. Parkour is like air for him. He has been at it for 6 years and loves everything about it. He loves the flow and spin styles of Parkour. His favorites are Rail Balance and Lazy Vaults. If you asked him what the craziest thing he has ever done was, he would have to think about it for a while. If there is something crazy to do, he has most likely done it. If he hasn’t, he will make sure to go out of his way to get it done."
]
stats = [
  "5'10\" 190 lbs",
  "5'6\" 175 lbs",
  "5'6\" <Invalid Request: Female>",
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

puts "Creating users"
instructor_firsts.each_with_index do |name, pos|
  User.create(
    email: "#{name}@ParkourUtah.com",
    first_name: "#{name.capitalize}",
    last_name: "#{instructor_lasts[pos].capitalize}",
    bio: "#{bios[pos]}",
    stats: "#{stats[pos]}",
    title: "#{titles[pos]}",
    avatar: "https://s3-us-west-2.amazonaws.com/pkut-default/#{name.capitalize}#{instructor_lasts[pos].capitalize}.jpg",
    avatar_2: "https://s3-us-west-2.amazonaws.com/pkut-default/#{name.capitalize}#{instructor_lasts[pos].capitalize}BW.jpg",
    # avatar: File.new("/Users/rocconicholls/Downloads/Serious/#{name.capitalize}#{instructor_lasts[pos].capitalize}.jpg"),
    # avatar_2: File.new("/Users/rocconicholls/Downloads/Goofy/#{name.capitalize}#{instructor_lasts[pos].capitalize}BW.jpg"),
    instructor_position: "#{pos + 1}",
    password: "#{name}pkfr4lf",
    role: 1
  )
  User.last.update(nickname: "#{instructor_nicks[pos]}") if instructor_nicks[pos].length > 0
  print "\e[32m. \e[0m"
end
puts "\nUsers complete"
if Rails.env == "development"
  puts "Creating Athletes"
  50.times do |athlete|
    athlete = RandomuserLocal.generate
    dependent = Dependent.create(
      user_id: User.all.sample.id,
      full_name: "#{athlete[:name][:first].capitalize} #{athlete[:name][:last].capitalize}",
      emergency_contact: athlete[:phone].gsub(/[^0-9]/, ''),
    )
    waiver = Waiver.create(
      dependent_id: dependent.id,
      signed: true,
      signed_for: dependent.full_name,
      signed_by: "Rocco"
    )
    dependent.generate_pin
    dependent.update(athlete_pin: "1234")
    print "\e[32m.\e[0m"
  end
  puts "\nAthletes complete"
end
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
# Event.create(
#   date: Faker::Time.between(Time.zone.now, 25.days.from_now, :day),
#   host: 1
#   title: 'Draper fundamentals',
#   description: "Bring your punch card and have a great time jumping on the huge Air Mat! We'll be going over advanced movements, so bring your A-Game!",
#   city: "Draper",
#   address: "12500 South 1300 East",
#   location_instructions: Faker::Lorem.sentence,
#   class_name: "special"
# )
puts "Creating Store items"
15.times do |t|
  LineItem.create(
    title: Faker::Commerce.product_name,
    description: Faker::Lorem.paragraph,
    cost_in_pennies: rand(25000),
    category: ["Other", "Shoes", "Shirts", "Stuff"].sample
  )
  print "\e[32m.\e[0m"
end
puts "\nCompleted Store items"
puts "Seeding Complete"
