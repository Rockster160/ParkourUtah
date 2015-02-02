# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)
cities = %w[ Sandy Draper Salt\ Lake\ City Lehi Orem Provo Murray Holladay South\ Jordan ]
classes = %w[ beginner intermediate conditioning jam tricking ]
100.times do |t|
  Event.create(
    date: Faker::Time.between(50.days.ago, 50.days.from_now, :day),
    host: Faker::Name.first_name,
    description: Faker::Lorem.paragraph,
    city: cities.sample, # Make expandable for any number of cities- main ones selectable, others in drop-down
    address: Faker::Address.street_address,
    location_instructions: Faker::Lorem.sentence,
    class_name: classes.sample
  )
end

Event.create(
  date: Faker::Time.between(Time.now, 25.days.from_now, :day),
  host: "Justin & Ryan",
  description: "Bring your punch card and have a great time jumping on the huge Air Mat! We'll be going over advanced movements, so bring your A-Game!",
  city: "Draper",
  address: "12500 South 1300 East",
  location_instructions: Faker::Lorem.sentence,
  class_name: "special"
)
