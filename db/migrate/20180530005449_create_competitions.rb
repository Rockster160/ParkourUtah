class CreateCompetitions < ActiveRecord::Migration[5.0]
  def change
    create_table :competitions do |t|
      t.belongs_to :spot
      t.string :name
      t.datetime :start_time

      t.timestamps
    end
    create_table :competitors do |t|
      t.belongs_to :athlete
      t.belongs_to :competition
      t.string :years_training
      t.string :instagram_handle
      t.string :song
      t.string :bio # 250
      t.string :stripe_charge_id

      t.timestamps
    end

    reversible do |migration|
      migration.up do
        spot = Spot.find_or_create_by(title: "University Place - The Orchard") do |spot|
          spot.approved = true
          spot.location = "University Place - The Orchard"
          spot.lat = "40.27619082824843"
          spot.lon = "-111.68098116455684"
        end
        Competition.create(
          spot: spot,
          name: "University Place Competition",
          start_time: DateTime.new(2018, 6, 25, 17, 30, 0, Time.find_zone("Mountain Time (US & Canada)").formatted_offset)
        )
      end
    end
  end
end
