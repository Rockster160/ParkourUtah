class AddSignUpDataToCompetitor < ActiveRecord::Migration[6.1]
  def change
    add_column :competitors, :signup_data, :text

    competition = Competition.find_by(slug: "fitcon2023")
    competition.update(
      sponsor_images: ["FitCon-comp20190412.png", "uspk.png"],
      option_costs: {
        youth: {
          all: {
            "1 Event": 20,
            "2 Events": 25,
            "3 Events": 30,
          }
        },
        adult: {
          all: {
            "1 Event": 30,
            "2 Events": 35,
            "3 Events": 40,
          },
        }
      }
    )
  end
end
