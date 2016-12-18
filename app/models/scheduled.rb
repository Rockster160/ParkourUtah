require 'net/http'
class Scheduled < ActiveRecord::Base

  def self.send_class_text
    Subscription.find_each do |subscriber|
      user = subscriber.user
      user.subscribed_events.where(date: 100.from_now..130.minutes.from_now).each do |event|
        next if event.cancelled?
        if user.notifications.text_class_reminder && user.notifications.sms_receivable
          num = user.phone_number
          if num.length == 10
            msg = "Hope to see you at our #{event.title} class today at #{event.date.strftime('%-l:%M')}!"
            ::SmsMailerWorker.perform_async(num, msg)
          end
        end
        if user.notifications.email_class_reminder?
          ::ClassReminderMailerWorker.perform_async(user.id, "Hope to see you at our #{event.title} class today at #{event.date.strftime('%-l:%M')}!")
        end
      end
    end
  end

  def self.remind_recurring_payments
    athletes_expiring_soon = Dependent.joins(:athlete_subscriptions).where('athlete_subscriptions.expires_at > ? AND athlete_subscriptions.expires_at < ?', 10.days.from_now.beginning_of_day, 10.days.from_now.end_of_day).where('athlete_subscriptions.auto_renew = true')
    by_users = athletes_expiring_soon.group_by(&:user_id)
    by_users.each do |user_id, athletes|
      ExpiringWaiverMailer.delay.notify_subscription_updating(user_id)
      SmsMailerWorker.perform_async('3852599640', "To update in 10 days: #{athletes.map(&:full_name)}")
    end
  end

  def self.send_summary(days)
    summary = {}
    payment = {}

    (0..(days - 1)).each do |days_ago|
      date = (Time.zone.now - days_ago.days).to_datetime
      first_date = date.beginning_of_day
      last_date = date.end_of_day

      events = Event.by_date(date)
      special = Attendance.where(event_id: 1).where(created_at: first_date..last_date).map(&:event)
      events += special
      events.flatten.compact.each do |event|
        instructors = {}
        if event.attendances.any?
          event.attendances.each do |attendance|
            instructor = attendance.user
            athlete = attendance.athlete

            instructors[instructor.full_name] ||= {}
            instructors[instructor.full_name]["students"] ||= []
            instructors[instructor.full_name]["pay"] ||= 0

            instructors[instructor.full_name]["students"] << "#{athlete.full_name} - #{attendance.type_of_charge}"
            pay = event.title == "Test" ? 15 : instructor.payment_multiplier
            instructors[instructor.full_name]["pay"] += pay

            attendance.sent!
          end
        else
          instructors[event.host_name] ||= {}
          instructors[event.host_name]["students"] = ["None"]
          instructors[event.host_name]["pay"] = 15
        end

        instructors.each do |instructor|
          pay = event.attendances.count > 5 ? instructor[1]["pay"] : 15
          instructor[1]["pay"] = pay
          payment[instructor[0]] ||= 0
          payment[instructor[0]] += pay
        end
        summary["#{date.strftime("%A %B %-d, %Y")}"] ||= {}
        if event.title == "Test"
          summary["#{date.strftime("%A %B %-d, %Y")}"]["Private Class"] = instructors
        else
          summary["#{date.strftime("%A %B %-d, %Y")}"]["#{event.title} - #{event.city} - #{event.date.strftime('%l:%M%p')}"] = instructors
        end
      end
    end

    total_summary_json = [summary, payment]

    ::SummaryMailerWorker.perform_async(total_summary_json)
  end

  def self.monthly_subscription_charges
    count = 0
    User.every do |user|
      recurring_athletes = []
      total_cost = user.athletes.inject(0) do |sum, athlete|
        valid_payment = (athlete.subscription && athlete.subscription.inactive? && athlete.subscription.auto_renew) || false
        recurring_athletes << athlete if valid_payment
        sum + (valid_payment ? athlete.subscription.cost_in_pennies : 0)
      end
      if recurring_athletes.count > 0 && user.stripe_id
        count += 1
        Stripe.api_key = ENV['PKUT_STRIPE_SECRET_KEY']
        charge = if total_cost > 0
          Stripe::Charge.create(
            :amount   => total_cost,
            :currency => "usd",
            :customer => user.stripe_id
          )
        else
          true
        end
        if charge || charge.status == "succeeded"
          SmsMailerWorker.perform_async('3852599640', "Successfully updated Subscription for #{user.email} at $#{(total_cost/100).round(2)}.")

          recurring_athletes.each do |athlete|
            old_sub = athlete.subscription
            old_sub.auto_renew = false
            old_sub.save
            athlete.athlete_subscriptions.create(cost_in_pennies: old_sub.cost_in_pennies)
          end
        else
          SmsMailerWorker.perform_async('3852599640', "There was an issue updating the subscription for #{user.email}.")
        end
      end
    end
    count
  end

  def self.waiver_checks
    Dependent.all.each do |athlete|
      user = athlete.user
      if athlete.waiver.exp_date.to_date == (Time.zone.now + 1.week).to_date
        if user.notifications.email_waiver_expiring
          ::ExpiringWaiverMailerWorker.perform_async(athlete.id)
        end
        if user.notifications.text_waiver_expiring && user.notifications.sms_receivable
          ::SmsMailerWorker.perform_async(user.phone_number, "The waiver belonging to #{athlete.full_name} is no longer active as of #{athlete.waiver.exp_date.strftime('%B %e')}. Head up to ParkourUtah.com to get it renewed!")
        end
      end
    end
  end

end
