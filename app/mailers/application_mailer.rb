class ApplicationMailer < ActionMailer::Base
  # http://localhost:7545/rails/mailers
  default from: 'parkourutah@gmail.com', template_path: "mailers/#{self.name.underscore}"
  layout 'mailer'

  def email(email, subject, body, email_type="")
    @user = User.where(email: email).first
    @email_type = email_type
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
    @athlete = Athlete.find(athlete_id)

    mail(to: @athlete.user.email, subject: "#{@athlete.full_name}'s waiver expires soon!")
  end

  def notify_subscription_updating(user_id)
    @user = User.find(user_id)
    range = (10.days.from_now.beginning_of_day..10.days.from_now.end_of_day)
    @expiring_athletes = @user.athletes
      .joins(:recurring_subscriptions)
      .where(recurring_subscriptions: { expires_at: range })
      .where(recurring_subscriptions: { auto_renew: true })
    @expiring_athletes = @expiring_athletes.select { |expiring_athlete| range.cover?(expiring_athlete.has_access_until) }
    return nil unless @expiring_athletes.any?

    mail(to: @user.email, subject: "Your recurring payment will charge again in 10 days!")
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

  def new_athlete_info_mail(fast_pass_ids)
    @athletes = fast_pass_ids.map { |fast_pass_id| Athlete.find(fast_pass_id) }

    mail(to: @athletes.first.user.email, subject: "New Athlete Information")
  end

  def pin_reset_mail(fast_pass_id)
    @athlete = Athlete.find(fast_pass_id.to_i)

    mail(to: @athlete.user.email, subject: "Request for ID or Pin Reset")
  end

  def summary_mail(summary, to_email=nil, include_totals=false)
    @include_totals = include_totals
    @summary = summary

    start_day = @summary.start_date.strftime("%A %B %-d, %Y")
    end_day = @summary.end_date.strftime("%A %B %-d, %Y")
    subject = "Class summary from #{start_day} to #{end_day}"

    if @include_totals
      xlsx = render_to_string layout: false, handlers: [:axlsx], formats: [:xlsx], template: "mailers/application_mailer/summary", locals: {summary: summary}
      xlsx = Base64.encode64(xlsx)
      attachments[@summary.start_date.strftime("Summary %B %Y") + '.xlsx'] = {mime_type: Mime::XLSX, content: xlsx, encoding: 'base64'}
      self.instance_variable_set(:@_lookup_context, nil)
    end

    mail(to: to_email || ENV['PKUT_EMAIL'], subject: subject)
  end

end
