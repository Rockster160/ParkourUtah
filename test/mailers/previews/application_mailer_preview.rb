class ApplicationMailerPreview < ActionMailer::Preview

  def email
    ApplicationMailer.email("rocco11nicholls@gmail.com", "Unsubscribe me!", "This user should be able to unsubscribe", "email_newsletter")
  end

  def welcome_mail
    email = ''
    ApplicationMailer.welcome_mail(email)
  end

  def class_reminder_mail
    user_id = 4
    event = Event.first
    msg = "Hope to see you at our #{event.title} class today at #{event.date.strftime('%l:%M')}!"
    ApplicationMailer.class_reminder_mail(user_id, msg)
  end

  def help_mail
    params = {}
    params["name"] = "Tom Smith"
    params["email"] = "tomsmith@gmail.com"
    params["phone"] = "(801) 123-4567"
    params["comment"] = "I need some help because I'm a poor, defenseless user."
    ApplicationMailer.help_mail(params)
  end

  def expiring_waiver_mail
    fast_pass_id = User[4].athletes.first.id
    ApplicationMailer.expiring_waiver_mail(fast_pass_id)
  end

  def notify_subscription_updating
    user_id = 4
    ApplicationMailer.notify_subscription_updating(user_id)
  end

  def customer_purchase_mail
    cart_id = User[4].cart.id
    email = 'rocco@parkourutah.com'
    ApplicationMailer.customer_purchase_mail(cart_id, email)
  end

  def key_gen_mail
    keys = 10.times.map {('a'..'z').to_a.shuffle[0,8].join}
    topic = 'Free Classes for life'
    ApplicationMailer.key_gen_mail(keys, topic)
  end

  def public_mailer
    key_id = RedemptionKey.last.try(:id) || RedemptionKey.create(line_item: LineItem.last)
    email = 'rocco@parkourutah.com'
    ApplicationMailer.public_mailer(key_id, email)
  end

  def low_credits_mail
    user_id = 4
    ApplicationMailer.low_credits_mail(user_id)
  end

  def new_athlete_info_mail
    fast_pass_ids = User[4].athletes.map(&:id)
    ApplicationMailer.new_athlete_info_mail(fast_pass_ids)
  end

  def new_athlete_notification_mail
    fast_pass_ids = User[4].athletes.map(&:id)
    ApplicationMailer.new_athlete_notification_mail(fast_pass_ids)
  end

  def pin_reset_mail
    fast_pass_id = User[4].athletes.first.id
    ApplicationMailer.pin_reset_mail(fast_pass_id)
  end

  def summary_mail
    summary = ClassSummaryCalculator.new(start_date: Time.zone.local(2016, 10, 1), end_date: Time.zone.local(2016, 11, 1)).generate
    ApplicationMailer.summary_mail(summary)
  end

  private

  def class_summary_fake_data
    [{"Tuesday March 17, 2015"=>
       {"Fundamentals - Orem -  4:30PM"=>
         {"Ryan Sannar"=>{"students"=>["Sam Smith - Credits"], "pay"=>15}},
        "Fundamentals - Saratoga Springs -  4:30PM"=>
         {"Justin Spencer"=>{"students"=>["Rocco Nicholls - Credits"], "pay"=>15},
          "Zeter Raimondo"=>
           {"students"=>["Jack Robinson - Credits", "Sam Smith - Credits"], "pay"=>15}},
        "Fundamentals - Saratoga Springs -  5:30PM"=>
         {"Jadon Erwin"=>{"students"=>["Jack Robinson - Credits"], "pay"=>15},
          "Justin Spencer"=>{"students"=>["Ryker Boy - Credits"], "pay"=>15}}},
      "Monday March 16, 2015"=>
       {"Fundamentals - Draper -  4:30PM"=>
         {"Marcos Jones"=>{"students"=>["Nick Vincent - Credits"], "pay"=>15},
          "Tony Mungiguerra"=>{"students"=>["Rocco Nicholls - Credits"], "pay"=>15},
          "Aaron Cornia"=>{"students"=>["Kim Krok - Credits"], "pay"=>15},
          "Jadon Erwin"=>{"students"=>["Nick Vincent - Credits"], "pay"=>15},
          "Stephen Lanteri"=>{"students"=>["Jack Robinson - Cash"], "pay"=>15},
          "Rocco Nicholls"=>{"students"=>["Sam Smith - Credits"], "pay"=>15},
          "Brianna Midas"=>{"students"=>["Ryker Boy - Cash"], "pay"=>15}},
        "Fundamentals - South Jordan -  5:30PM"=>
         {"Marcos Jones"=>{"students"=>["Jack Robinson - Credits"], "pay"=>15},
          "Stephen Lanteri"=>
           {"students"=>
             ["Rocco Nicholls - Credits",
              "Kim Krok - Credits",
              "Nick Vincent - Credits",
              "Jack Robinson - Credits",
              "Sam Smith - Credits",
              "Ryker Boy - Credits"],
            "pay"=>18}}},
      "Sunday March 15, 2015"=>
       {"Advanced - Sandy -  7:30PM"=>
         {"Rocco Nicholls"=>{"students"=>["Rocco Nicholls - Credits"], "pay"=>15},
          "Ryan Sannar"=>
           {"students"=>["Nick Vincent - Credits", "Kim Krok - Cash"], "pay"=>15},
          "Stephen Lanteri"=>
           {"students"=>
             ["Chesley Harvey - Cash",
              "Nedra Hermiston - Cash",
              "Mrs. Erik Hamill - Cash",
              "Madeline Wuckert - Cash",
              "Francesca Daniel DDS - Cash",
              "Bessie Quigley - Cash",
              "Miss Jonathan Luettgen - Cash",
              "Michael Kirlin Jr. - Cash",
              "Rosella Senger Sr. - Cash",
              "Miss Daija Bauch - Cash",
              "Shad Runolfsdottir - Cash"],
            "pay"=>33}}},
      "Saturday March 14, 2015"=>
       {"Fundamentals - Ogden - 11:00AM"=>{}, "Fundamentals - Springville - 11:00AM"=>{}},
      "Thursday March 12, 2015"=>
       {"Fundamentals - Provo -  4:30PM"=>{},
        "Fundamentals - Salt Lake City -  4:30PM"=>{},
        "Fundamentals - Herriman -  5:30PM"=>{}},
      "Wednesday March 11, 2015"=>
       {"Fundamentals - Sandy -  4:30PM"=>{},
        "Fundamentals - Vernal -  4:30PM"=>{},
        "Fundamentals - Salt Lake City -  5:30PM"=>{}}},
     {"Ryan Sannar"=>30,
      "Justin Spencer"=>30,
      "Zeter Raimondo"=>15,
      "Jadon Erwin"=>30,
      "Marcos Jones"=>30,
      "Tony Mungiguerra"=>15,
      "Aaron Cornia"=>15,
      "Stephen Lanteri"=>66,
      "Rocco Nicholls"=>30,
      "Brianna Midas"=>15}]
  end

end
