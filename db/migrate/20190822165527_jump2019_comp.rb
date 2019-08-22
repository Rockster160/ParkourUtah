class Jump2019Comp < ActiveRecord::Migration[5.0]
  def up
    Competition.create(
      name: "Jump Up 2019",
      slug: "JumpUp2019",
      start_time: DateTime.parse("August 31st 2019 at 12pm"),
      description: "Welcome to the Registration for the 2nd Annual Parkour Competition at University Place in Orem Utah!\n\nThis year is going to be even bigger than last year, we have $700 in CASH PRIZES!!!! In addition we’re going to have the great and fantastic Joey Adrian assisting with competition prep and judging/mc-ing along with Utah’s Own Calen “Bane-Blade” Chan!\n\nThe competitions will be held on the grounds of The Orchard at University Place Mall on Saturday August 31st.\n\nYouth (7-13) Speed starts at 12:00pm\nYouth (7-13) Freestyle starts at 1:30pm\nAdult (14+) Speed starts at 3:00pm\nAdult (14+) Freestyle starts at 5:00pm\n\nEach competition will have a qualifying and a finals round so be prepared to run twice!\n\nLike last year prior to the competition there will be an open parkour space where we will be teaching basic techniques, room to jam, and people will have the chance to spectate. Invite your friends and family to see you compete!!!\n\nYouth Cost to compete in a single event is $20. Youth Cost to compete in both the speed and freestyle is $30.\nAdult Cost to compete in a single event is $30. Adult Cost to compete in both the speed and freestyle events is $45.\n\nTo register sign in and click the register button below, then specify if you’d prefer single event or double event.\n\nAs we did last time you are welcome to select a song for your run to play so long as there is no lewd/suggestive or crude language. Please provide the name and artist of the song.",
      option_costs: {
        youth: {
          early: {
            "Single Event": 20,
            "Double Event": 30
          },
          late: {
            "Single Event": 20,
            "Double Event": 30
          }
        },
        adult: {
          early: {
            "Single Event": 30,
            "Double Event": 45
          },
          late: {
            "Single Event": 30,
            "Double Event": 45
          }
        }
      },
      sponsor_images: ["UPLogo.png", "YGTLogo.png"],
      coupon_codes: {
        "PRIVILEGE-OF-ROYALTY" => "0",
        "KING-SOLOMON"         => "cost * 0.50",
        "2ND-RODEO"            => "cost * 0.80",
        "I-AM-THE-BANE-BLADE"  => "cost * 0.85",
        "10-FINGERS-AND-TOES"  => "cost * 0.90"
      }
    )
  end

  def down
    Competition.find_by(slug: "JumpUp2019").try(:destroy)
  end
end
