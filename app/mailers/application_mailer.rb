class ApplicationMailer < ActionMailer::Base
  default from: 'parkourutah@gmail.com', template_path: "mailers/#{self.name.underscore}"
  layout 'mailer'

  def email(email, subject, body)
    @body = body.html_safe

    mail({
      to: email,
      subject: subject
    })
  end

  def welcome_mail(email)
    mail(to: email, subject: "Thanks for signing up at ParkourUtah!")
  end

  def class_reminder_mail(user_id, msg)
    @user = User.find(user_id)
    @msg = msg

    mail(to: @user.email, subject: "Class Reminder")
  end

  def help_mail(params)
    @name = params["name"]
    @email = params["email"]
    @phone = params["phone"]
    @body = params["comment"]
    mail(to: ENV['PKUT_EMAIL'], subject: "Request for Contact")
  end

  def expiring_waiver_mail(athlete_id)
    @athlete = Dependent.find(athlete_id.to_i)

    mail(to: @athlete.user.email, subject: "#{@athlete.full_name}'s waiver expires soon!")
  end

  def notify_subscription_updating(user_id)
    @user = User.find(user_id)
    range = (10.days.from_now.beginning_of_day..10.days.from_now.end_of_day)
    @expiring_athletes = @user.dependents.joins(:athlete_subscriptions).where('athlete_subscriptions.expires_at > ? AND athlete_subscriptions.expires_at < ?', range.min, range.max).where('athlete_subscriptions.auto_renew = true')
    @expiring_athletes = @expiring_athletes.select { |a| range.cover?(a.subscription.expires_at) }
    return nil unless @expiring_athletes.any?

    mail(to: @user.email, subject: "Your recurring payment will charge again soon!")
  end

  def customer_purchase_mail(cart_id, email)
    @cart = Cart.find(cart_id.to_i)
    @order_items = @cart.cart_items
    @is_gift_card = @order_items.any? { |cart_item| ["Gift Card"].include?(cart_item.item.category) }
    @is_physical = @order_items.any? { |cart_item| ["Clothing", "Accessories"].include?(cart_item.item.category) }
    @adds_credits = @order_items.any? { |cart_item| cart_item.item.credits > 0 }
    @is_subscription = @order_items.any? { |cart_item| cart_item.item.is_subscription? }
    @user = @cart.user
    @address = @user.try(:address)

    mail(to: email, subject: "Order confirmation")
  end

  def public_mailer(key_id, email)
    @key = RedemptionKey.find(key_id)
    mail(to: email, subject: "Your ParkourUtah Gift Card")
  end

  def low_credits_mail(user_id)
    @user = User.find(user_id.to_i)

    mail(to: @user.email, subject: "You are almost out of class credits!")
  end

  def new_athlete_info_mail(athlete_ids)
    @athletes = athlete_ids.map { |athlete_id| Dependent.find(athlete_id) }

    mail(to: @athletes.first.user.email, subject: "New Athlete Information")
  end

  def new_athlete_notification_mail(athlete_ids)
    @athletes = athlete_ids.map { |athlete_id| Dependent.find(athlete_id) }
    @user = @athletes.first.user

    mail(to: ENV["PKUT_EMAIL"], subject: "Somebody made some athletes!")
  end

  def pin_reset_mail(athlete_id)
    @athlete = Dependent.find(athlete_id.to_i)

    mail(to: @athlete.user.email, subject: "Request for ID or Pin Reset")
  end

  def summary_mail(summary)
    @summary = summary[0]
    @payment = summary[1]
    range = summary.first.keys
    dates = range.length == 1 ? "for #{range.first}." : "from #{range.last} to #{range.first}."
    mail(to: ENV['PKUT_EMAIL'], subject: "Class summary #{dates}")
  end
end
