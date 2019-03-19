c = Competition.create(
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

puts "Errors: \e[31m#{c.errors.full_messages}\e[0m"
puts "#{c}"
