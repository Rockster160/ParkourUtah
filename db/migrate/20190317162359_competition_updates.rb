class CompetitionUpdates < ActiveRecord::Migration[5.0]
  def change
    add_column :competitions, :slug, :string
    add_column :competitions, :description, :text
    add_column :competitions, :option_costs, :text
    add_column :competitions, :sponsor_images, :text

    add_column :competitors, :selected_comp, :string

    comp = Competition.first
    if comp.present?
      comp.update(
        description: "Welcome to the registration for Parkour Utah’s First Annual Parkour Competition held at Univeristy Place in Utah County! \n\nWe're really excited to get this going and to turn this into one of the largest competitions in Utah.\n\nThe competition will be held on the grounds of The Orchard at University Place on Monday June 25th. The Youth competition will start at 4:00pm the Adult competition with start at 7:00pm. Prior to the competition a free parkour seminar and jam will be held starting at 2:00pm, you are welcome to invite anyone to attend and learn some parkour. Ages 7 and up will be allowed to compete.\n\nThis competition costs $35, payment and a secondary waiver follows registration. We will email/text you when your registration is approved.\n\nYouth runs will be 45 seconds long. Adult runs will be 1 minute long. You may select a song to play for your run so long as the song does not contain lewd/suggestive or crude language. Please post the name of or a youtube link for the song.",
        option_costs: {all: 35},
        sponsor_images: ["UPLogo.png", "YGTLogo.png"]
      )
    end

    Competition.create(
      name: "Jump FitCon 2019",
      slug: "fitcon2019",
      start_time: DateTime.parse("April 12th 2019 at 5pm"),
      description: "Welcome to the registration for Parkour Utah's FitCon 2019 Parkour Speedrun and Freestyle Competition.\n\nThis is our first Competition at FitCon and we're incredibly excited to have you participate! We are holding Youth Competitions, for ages 13 and under, and Adult Competitions for ages 14+.\n\nThis is a two day competition encompassing both speed-based and freestyle-based competitions for youth and adult groups. The competitions for Youth (Speed and Freestyle) will be held on Friday April 12th 2019 and the Adult Competitions (Speed and Freestyle) will be held on Saturday April 13th 2019. Full details and schedule will be posted on our Facebook page and posted here. Potential changes may be made based on scheduling updates, etc... Any changes will be communicated to you via email, text, etc...\n\nPrior to the competition, parkour lessons will be provided on the course. The course will be open to all attendees of Fitcon who sign a waiver with Parkour Utah. As a competitor you will have access to the course prior to the competition and unfettered access to the course at a minimum of at least 15 minutes prior to the competition start, possibly longer.\n\nEntrance into Fitcon for competitors is free. Any competitors under the age of 18 are required to be accompanied by 1 parent or guardian, who will be granted free entrance to Fitcon as part your entry free at no additional cost.\n\nYouth Costs:\n-Freestyle Comp: $40 ($50 Week Of Competition)\n-Speed Comp: $25 ($35 Week Of Competition)\n-Both: $55 ($70 Week of Competitions)\n\nAdult Costs:\n-Freestyle Comp: $50 ($60 Week Of Competition)\n-Speed Comp: $35 ($45 Week Of Competition)\n-Both: $70 ($90 Week of Competitions)\n\nYouth Freestyle runs will be allowed a maximum of 1 full minute. Adult Freestyle Runs will allow a maximum of 1 minute 30 seconds. Maximum time allotted for Speed Runs, regardless of age group, is 2 minutes.",
      option_costs: {
        youth: {
          early: {
            "Freestyle Comp": 40,
            "Speed Comp": 25,
            "Both": 55
          },
          late: {
            "Freestyle Comp": 50,
            "Speed Comp": 35,
            "Both": 70
          }
        },
        adult: {
          early: {
            "Freestyle Comp": 50,
            "Speed Comp": 35,
            "Both": 70
          },
          late: {
            "Freestyle Comp": 60,
            "Speed Comp": 45,
            "Both": 90
          }
        }
      },
      sponsor_images: ["FitCon-comp20190412.png", "YGTLogo.png"]
    )
  end
end
