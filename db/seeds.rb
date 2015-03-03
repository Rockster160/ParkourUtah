# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)
cities = %w[ Sandy Draper Salt\ Lake\ City Lehi Orem Provo Murray Holladay South\ Jordan ]
classes = %w[ beginner intermediate conditioning jam tricking ]


User.create(
  email: "test@email.com",
  first_name: "Rocco",
  last_name: "Nicholls",
  bio: Faker::Lorem.paragraphs(5),
  password: "password",
  role: 2
)

10.times do |t|
  User.create(
    email: "instructor#{t}@email.com",
    first_name: Faker::Name.first_name,
    last_name: Faker::Name.last_name,
    bio: Faker::Lorem.paragraph,
    password: "password",
    role: 1
  )
  User.create(
    email: "dummy#{t}@email.com",
    first_name: Faker::Name.first_name,
    last_name: Faker::Name.last_name,
    password: "password",
  )
end

instructors = User.where("role > ?", 0).pluck(:first_name)

50.times do |t|
  # Thursday
  Event.create(
    date: DateTime.new(2015, 1, 1, 16, 30) + (t.weeks),
    host: 'Scott May',
    description: 'Our weekly Provo fundamentals class. Wear comfortable clothing that is easy to move in and a water bottle. Class runs for and hour and a half and involves moving all around the park. Make sure to bring your punch card or $12 via Credit Card for a single class. If you haven''t ever been before a WAIVER will need to be signed by you (if you\'re 18+) or a parent. If you have any questions about the class feel free to contact the teacher,
    Scott May, via text or call 435-549-0303.',
    city: 'Provo',
    token: 1,
    address: 'Kiwanis Park Tennis Courts, 8200 North 1100 East',
    location_instructions: '',
    class_name: 'fundamentals'
  )
  # Thursday
  Event.create(
    date: DateTime.new(2015, 1, 1, 16, 30) + (t.weeks),
    host: 'Justin Spencer',
    description: 'Our weekly Liberty Park fundamentals class. Wear comfortable clothing that is easy to move in and a water bottle. Class runs for and hour and a half and involves moving all around the park. Make sure to bring your punch card or $12 via Credit Card for a single class. If you haven''t ever been before a WAIVER will need to be signed by you (if you\'re 18+) or a parent. If you have any questions about the class feel free to contact the teacher,
    Justin Spencer, via text or call 801-580-9274.',
    city: 'Salt Lake City',
    token: 2,
    address: 'Liberty Park, 600 East 900 South',
    location_instructions: '',
    class_name: 'fundamentals'
  )
  # Friday
  Event.create(
    date: DateTime.new(2015, 1, 2, 16, 30) + (t.weeks),
    host: 'Ryan Sannar',
    description: 'Our second bi-weekly Sandy fundamentals class. Wear comfortable clothing that is easy to move in and a water bottle. Class runs for and hour and a half and involves moving all around the park. Make sure to bring your punch card or $12 via Credit Card for a single class. If you haven''t ever been before a WAIVER will need to be signed by you (if you\'re 18+) or a parent. If you have any questions about the class feel free to contact the teacher,
    Ryan Sannar, via text or call 801-669-7743.',
    city: 'Sandy',
    token: 3,
    address: 'Crestwood Park 1700 Siesta Drive',
    location_instructions: '',
    class_name: 'fundamentals'
  )
  # Saturday
  Event.create(
    date: DateTime.new(2015, 1, 3, 16) + (t.weeks),
    host: 'Marcos Jones',
    description: 'Our second bi-weekly Vernal fundamentals class. Wear comfortable clothing that is easy to move in and a water bottle. Class runs for and hour and a half and involves moving all around the park. Make sure to bring your punch card or $12 via Credit Card for a single class. If you haven''t ever been before a WAIVER will need to be signed by you (if you\'re 18+) or a parent. If you have any questions about the class feel free to contact the teacher,
    Marcos Jones, via text or call 435-612-0532.',
    city: 'Vernal',
    token: 4,
    address: 'Ashley Valley Community Park',
    location_instructions: '',
    class_name: 'fundamentals'
  )
  # Monday
  Event.create(
    date: DateTime.new(2015, 1, 5, 16, 30) + (t.weeks),
    host: 'Justin Spencer',
    description: 'Our weekly Draper fundamentals class. Wear comfortable clothing that is easy to move in and a water bottle. Class runs for and hour and a half and involves moving all around the park. Make sure to bring your punch card or $12 via Credit Card for a single class. If you haven''t ever been before a WAIVER will need to be signed by you (if you\'re 18+) or a parent. If you have any questions about the class feel free to contact the teacher,
    Justin Spencer, via text or call 801-580-9274.',
    city: 'Draper',
    token: 5,
    address: '944 East Vestry Road',
    location_instructions: '',
    class_name: 'fundamentals'
  )
  # Tuesday
  Event.create(
    date: DateTime.new(2015, 1, 6, 16, 30) + (t.weeks),
    host: 'Ryan Sannar',
    description: 'Our weekly Orem fundamentals class. Wear comfortable clothing that is easy to move in and a water bottle. Class runs for and hour and a half and involves moving all around the park. Make sure to bring your punch card or $12 via Credit Card for a single class. If you haven''t ever been before a WAIVER will need to be signed by you (if you\'re 18+) or a parent. If you have any questions about the class feel free to contact the teacher,
    Ryan Sannar, via text or call 801-669-7743.',
    city: 'Orem',
    token: 6,
    address: '600 South State Street, Orem',
    location_instructions: '',
    class_name: 'fundamentals'
  )
  # Tuesday
  Event.create(
    date: DateTime.new(2015, 1, 6, 16, 30) + (t.weeks),
    host: 'Ryan Sannar',
    description: 'Our weekly Saratoga Springs fundamentals class. Wear comfortable clothing that is easy to move in and a water bottle. Class runs for and hour and a half and involves moving all around the park. Make sure to bring your punch card or $12 via Credit Card for a single class. If you haven''t ever been before a WAIVER will need to be signed by you (if you\'re 18+) or a parent. If you have any questions about the class feel free to contact the teacher,
    Ryan Sannar, via text or call 801-669-7743.',
    city: 'Saratoga Springs',
    token: 7,
    address: 'Harvest Hills Park, 2104 North Providence Drive',
    location_instructions: '',
    class_name: 'fundamentals'
  )
  # Wednesday
  Event.create(
    date: DateTime.new(2015, 1, 7, 16, 30) + (t.weeks),
    host: 'Ryan Sannar',
    description: 'Our first bi-weekly Sandy fundamentals class. Wear comfortable clothing that is easy to move in and a water bottle. Class runs for and hour and a half and involves moving all around the park. Make sure to bring your punch card or $12 via Credit Card for a single class. If you haven''t ever been before a WAIVER will need to be signed by you (if you\'re 18+) or a parent. If you have any questions about the class feel free to contact the teacher,
    Ryan Sannar, via text or call 801-669-7743.',
    city: 'Sandy',
    token: 8,
    address: '1700 Siesta Drive',
    location_instructions: '',
    class_name: 'fundamentals'
  )
  # Wednesday
  Event.create(
    date: DateTime.new(2015, 1, 7, 16, 30) + (t.weeks),
    host: 'Marcos Jones',
    description: 'Our first bi-weekly Vernal fundamentals class. Wear comfortable clothing that is easy to move in and a water bottle. Class runs for and hour and a half and involves moving all around the park. Make sure to bring your punch card or $12 via Credit Card for a single class. If you haven''t ever been before a WAIVER will need to be signed by you (if you\'re 18+) or a parent. If you have any questions about the class feel free to contact the teacher,
    Marcos Jones, via text or call 435-612-0532.',
    city: 'Vernal',
    token: 9,
    address: 'Ashley Valley Community Park',
    location_instructions: '',
    class_name: 'fundamentals'
  )
end

Event.create(
  date: Faker::Time.between(Time.zone.now, 25.days.from_now, :day),
  host: 2,
  description: "Bring your punch card and have a great time jumping on the huge Air Mat! We'll be going over advanced movements, so bring your A-Game!",
  city: "Draper",
  address: "12500 South 1300 East",
  location_instructions: Faker::Lorem.sentence,
  class_name: "special"
)

def generateToken
  token = ''
  (1..10).to_a.sample.times do |t|
    token += (('a'..'z').to_a + ('A'..'Z').to_a).sample
  end
  token
end

15.times do |t|
  LineItem.create(
    title: Faker::Commerce.product_name,
    description: Faker::Lorem.paragraph,
    cost_in_pennies: rand(25000),
    category: ["Other", "Shoes", "Shirts", "Stuff"].sample
  )
end
