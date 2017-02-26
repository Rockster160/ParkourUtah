class ScheduleWorker
  include Sidekiq::Worker
  include ActionView::Helpers::NumberHelper
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
  #   slack_message << "#{athlete.id} #{athlete.full_name} - Athlete ID: #{athlete.fast_pass_id.to_s.rjust(4, "0")} Pin: #{athlete.fast_pass_pin.to_s.rjust(4, "0")}\n"
  # end
  # slack_message << "Referred By: #{current_user.referrer}"
  # channel = Rails.env.production? ? "#new-users" : "#slack-testing"
  # SlackNotifier.notify(slack_message, channel)

  private

  def post_to_custom_logger(params)
    CustomLogger.log_blip!("\e[32m")
  end

  def send_class_text(params)
    date_range = minutes_from_now(110)..minutes_from_now(130)
    Event.joins(event_schedule: :event_subscriptions).where(date: date_range).find_each do |subscribed_event|
      next if subscribed_event.cancelled?
      subscribed_users = subscribed_event.event_schedule.subscribed_users
      subscribed_users.each do |user|
        if user.notifications.text_class_reminder && user.notifications.sms_receivable
          num = user.phone_number
          if num.length == 10
            msg = "Hope to see you at our #{subscribed_event.title} class today at #{subscribed_event.date.strftime('%-l:%M')}!"
            Message.text.create(body: msg, chat_room_name: num, sent_from_id: 0).deliver
          end
        end
        if user.notifications.email_class_reminder?
          ::ClassReminderMailerWorker.perform_async(user.id, "Hope to see you at our #{subscribed_event.title} class today at #{subscribed_event.date.strftime('%-l:%M')}!")
        end
      end
    end
  end

  def waiver_checks(params)
    Athlete.find_each do |athlete|
      user = athlete.user
      next unless athlete.waiver.present?
      if athlete.waiver.expiry_date.to_date == weeks_from_now(1).to_date
        if user.notifications.email_waiver_expiring
          ApplicationMailer.expiring_waiver_mail(athlete.id).deliver
        end
        if user.notifications.text_waiver_expiring && user.notifications.sms_receivable
          msg = "The waiver belonging to #{athlete.full_name} is no longer active as of #{athlete.waiver.expiry_date.strftime('%B %-d')}. Head up to ParkourUtah.com to get it renewed!"
          Message.text.create(body: msg, chat_room_name: user.phone_number, sent_from_id: 0).deliver
        end
      end
    end
  end

  def remind_recurring_payments(params)
    athletes_expiring_soon = Athlete.joins(:recurring_subscriptions)
      .where(recurring_subscriptions: { expires_at: (days_from_now(10).beginning_of_day)..(days_from_now(10).end_of_day) })
      .where(recurring_subscriptions: { auto_renew: true })
    by_users = athletes_expiring_soon.group_by(&:user_id)

    by_users.each do |user_id, athletes|
      ApplicationMailer.notify_subscription_updating(user_id).deliver

      slack_message = "Unlimited Subscriptions to update in 10 days: #{athletes.map(&:full_name).join(", ")}"
      channel = Rails.env.production? ? "#purchases" : "#slack-testing"
      SlackNotifier.notify(slack_message, channel)
    end
  end

  def monthly_subscription_charges(params)
    Stripe.api_key = ENV['PKUT_STRIPE_SECRET_KEY']
    RecurringSubscription.assigned.auto_renew.inactive.group_by(&:user).each do |user, recurring_subscriptions|
      recurring_subscriptions.group_by(&:stripe_id).each do |stripe_id, stripe_subscriptions|
        total_cost = stripe_subscriptions.map(&:cost_in_pennies).sum
        begin
          stripe_charge = Stripe::Charge.create({
            amount:   total_cost,
            currency: "usd",
            customer: stripe_subscriptions.first.stripe_id
          })
        rescue Stripe::CardError => e
          stripe_charge = {failure_message: "Stripe Error: Failed to Charge: #{e}"}
        rescue => e
          stripe_charge = {failure_message: "Failed to Charge: #{e}"}
        end
        if stripe_charge.try(:status) == "succeeded"
          slack_message = "Charged Unlimited Subscriptions for #{user.email} at #{number_to_currency(total_cost/100.to_f)}."
          channel = Rails.env.production? ? "#purchases" : "#slack-testing"
          SlackNotifier.notify(slack_message, channel)

          stripe_subscriptions.each do |recurring_subscription|
            recurring_subscription.update(auto_renew: false)
            new_sub = user.recurring_subscriptions.create(athlete_id: recurring_subscription.athlete_id, auto_renew: true, cost_in_pennies: recurring_subscription.cost_in_pennies)
            unless new_sub.persisted?
              SlackNotifier.notify("Failed to create new sub: ```#{new_sub.try(:attributes)}```", "#server-errors")
            end
          end
        else
          SlackNotifier.notify("There was an issue updating the subscription for #{user.email}\n```#{stripe_charge}```", "#server-errors")
        end
      end
    end
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
    ApplicationMailer.summary_mail(summary, nil, params["scope"] == "month").deliver
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
