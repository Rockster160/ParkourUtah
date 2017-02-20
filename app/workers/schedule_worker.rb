class ScheduleWorker
  include Sidekiq::Worker
  sidekiq_options retry: false

  def perform(task_values)
    task_values.each do |task, params|
      unless task.nil?
        self.send(task.to_sym, params)
      end
    end
  end

  # slack_message = "New User: <#{admin_user_path(current_user)}|#{current_user.id} #{current_user.email}>\n"
  # current_user.athletes.each do |athlete|
  #   slack_message << "#{athlete.id} #{athlete.full_name} - Athlete ID: #{athlete.zero_padded(athlete.athlete_id, 4)} Pin: #{athlete.zero_padded(athlete.athlete_pin, 4)}\n"
  # end
  # slack_message << "Referred By: #{current_user.referrer}"
  # channel = Rails.env.production? ? "#new-users" : "#slack-testing"
  # SlackNotifier.notify(slack_message, channel)

  private

  def post_to_custom_logger(params)
    CustomLogger.log_blip!("\e[32m")
  end

  def send_class_text(params)
    date_range = minutes_from_now(100)..minutes_from_now(130)
    Subscription.find_each do |subscriber|
      user = subscriber.user
      user.subscribed_events.joins(:events).where(events: {date: date_range}).each do |schedule|
        event = schedule.events.where(date: date_range).first
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

  def waiver_checks(params)
    Dependent.all.each do |athlete|
      user = athlete.user
      if athlete.waiver.exp_date.to_date == weeks_from_now(1).to_date
        if user.notifications.email_waiver_expiring
          ::ExpiringWaiverMailerWorker.perform_async(athlete.id)
        end
        if user.notifications.text_waiver_expiring && user.notifications.sms_receivable
          ::SmsMailerWorker.perform_async(user.phone_number, "The waiver belonging to #{athlete.full_name} is no longer active as of #{athlete.waiver.exp_date.strftime('%B %e')}. Head up to ParkourUtah.com to get it renewed!")
        end
      end
    end
  end

  def remind_recurring_payments(params)
    athletes_expiring_soon = Dependent.joins(:athlete_subscriptions)
      .where('athlete_subscriptions.expires_at > ? AND athlete_subscriptions.expires_at < ?', days_from_now(10).beginning_of_day, days_from_now(10).end_of_day)
      .where('athlete_subscriptions.auto_renew = true')
    by_users = athletes_expiring_soon.group_by(&:user_id)

    by_users.each do |user_id, athletes|
      ExpiringWaiverMailer.notify_subscription_updating(user_id).deliver_now

      slack_message = "Unlimited Subscriptions to update in 10 days: #{athletes.map(&:full_name).join(", ")}"
      channel = Rails.env.production? ? "#purchases" : "#slack-testing"
      SlackNotifier.notify(slack_message, channel)
    end
  end

  def monthly_subscription_charges(params)
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
          slack_message = "Charged Unlimited Subscriptions for #{user.email} at $#{(total_cost/100).round(2)}."
          channel = Rails.env.production? ? "#purchases" : "#slack-testing"
          SlackNotifier.notify(slack_message, channel)

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

  def send_summary(params)
    return true unless Rails.env.production? || params["send_without_prod"]
    now = Time.zone.now
    last_week = days_ago(7)
    start_date, end_date = case params["scope"]
    when "day" then [now.beginning_of_day, now.end_of_day]
    when "month" then [last_week.beginning_of_month, last_week.end_of_month]
    end
    summary = ClassSummaryCalculator.new(start_date: start_date, end_date: end_date).generate
    ApplicationMailer.summary_mail(summary, nil, params["scope"] == "month").deliver_now
  end

  def pull_logs_from_s3(params)
    return unless Rails.env.production?
    s3 = AWS::S3.new
    buckets = [s3.buckets["pkut-default"], s3.buckets["pkut-uploads"]]
    buckets.each do |bucket|
      log_files = bucket.objects.with_prefix('logs')
      log_files.each do |log_file|
        file_body = log_file.read
        logit = AwsLogger.create(orginal_string: file_body)
        if logit.persisted? || logit.is_log_request?
          log_file.delete
        else
          unless logit.is_log_request?
            SlackNotifier.notify("Failed to delete file: \n#{log_file}:```#{file_body}```", "#server-errors")
          end
        end
      end
    end
  end

  def minutes_from_now(seconds)
    Time.zone.now + (seconds * 60)
  end

  def weeks_from_now(seconds)
    Time.zone.now + (seconds * 60 * 60 * 24 * 7)
  end

  def days_ago(seconds)
    Time.zone.now - (seconds * 60 * 60 * 24)
  end

  def days_from_now(seconds)
    Time.zone.now + (seconds * 60 * 60 * 24)
  end

end
