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

100.times do |t|
  Event.create(
    date: Faker::Time.between(50.days.ago, 50.days.from_now, :day),
    host: instructors.sample,
    description: Faker::Lorem.paragraph,
    city: cities.sample, # Make expandable for any number of cities- main ones selectable, others in drop-down
    address: Faker::Address.street_address,
    location_instructions: Faker::Lorem.sentence,
    class_name: classes.sample
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

15.times do |t|
  LineItem.create(
    display: "https://robohash.org/#{instructors.sample}?bgset=bg#{(1..9).to_a.sample}&size=300x400",
    title: Faker::Commerce.product_name,
    description: Faker::Lorem.paragraph,
    cost: (rand(25000).to_f/100).round(2),
    category: ["Other", "Shoes", "Shirts", "Stuff"].sample
  )
end
