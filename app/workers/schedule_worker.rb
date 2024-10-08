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

  def uptime_ping(params)
    HTTParty.post(
      "https://ardesian.com/jil/#{ENV["JIL_SIDEKIQ_PING_UUID"]}",
      body: { sidekiq: { app: :pkut } }.to_json,
      headers: {
        "Authorization" => "Bearer #{ENV["JIL_API_KEY"]}",
        "Content-Type" => "application/json"
      }
    )
  end

  def post_to_custom_logger(params)
    CustomLogger.log_blip!("\e[32m")
  end

  def send_class_text(params)
    date_range = minutes_from_now(110)..minutes_from_now(130)
    EventSchedule.joins(:event_subscriptions).distinct.events_today.each do |subscribed_event|
      next if subscribed_event.cancelled?
      next unless date_range.cover?(subscribed_event.date)
      subscribed_users = subscribed_event.event_schedule.subscribed_users
      subscribed_users.each do |user|
        if user.notifications.text_class_reminder && user.can_receive_sms
          num = user.phone_number
          if num.length == 10
            msg = "Hope to see you at our #{subscribed_event.title} class today at #{subscribed_event.date.strftime('%-l:%M')}!"
            Message.text.create(body: msg, chat_room_name: num, sent_from_id: 0).deliver
          end
        end
        if user.notifications.email_class_reminder?
          ApplicationMailer.class_reminder_mail(user.id, "Hope to see you at our #{subscribed_event.title} class today at #{subscribed_event.date.strftime('%-l:%M')}!").deliver_later
        end
      end
    end
  end

  def subscribe_new_user(params)
    date_range = minutes_ago(130)..minutes_ago(110)
    EventSchedule.joins(:event_subscriptions).distinct.events_today.each do |attended_event|
      next if attended_event.cancelled?
      next unless date_range.cover?(attended_event.date)
      event_schedule = attended_event.event_schedule
      attended_event.attendances.group_by { |attendance| attendance.athlete.user_id }.each do |user_id, attendances|
        user = User.find(user_id)
        next unless user.can_receive_sms? && user.notifications.text_class_reminder?
        next if user.subscribed_events.where(id: event_schedule.id).any?
        next unless attended_event.event_schedule.attendances.where(athlete_id: user.athlete_ids).where.not(event_id: attended_event.id).none?
        athletes = attendances.map(&:athlete)
        names = athletes.map { |athlete| athlete.full_name.split(" ").first.squish }.to_sentence

        num = user.phone_number
        if num.length == 10 && user.event_subscriptions.find_or_create_by(event_schedule_id: event_schedule.id)
          msg = "Thanks for visiting #{attended_event.title}, we loved having #{names} in class!\nWe've set up an auto text message reminder to go out before class each week. To review and edit your text message subscriptions please visit parkourutah.com/account#subscriptions when logged into your Parkour Utah account. Thank you!"
          Message.text.create(body: msg, chat_room_name: num, sent_from_id: 0).deliver
        end
      end
    end
    nil
  end

  def waiver_checks(params)
    Athlete.find_each do |athlete|
      user = athlete.user
      next unless athlete.waiver.present?
      if athlete.waiver.expiry_date.to_date == weeks_from_now(1).to_date
        if user.notifications.email_waiver_expiring
          ApplicationMailer.expiring_waiver_mail(athlete.id).deliver
        end
        if user.notifications.text_waiver_expiring && user.can_receive_sms
          msg = "The waiver belonging to #{athlete.full_name} is no longer active as of #{athlete.waiver.expiry_date.strftime('%B %-d')}. Head up to ParkourUtah.com/waivers to get it renewed!"
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
    RecurringSubscription.assigned.auto_renew.expired.available.group_by(&:user).each do |user, recurring_subscriptions|
      recurring_subscriptions.group_by(&:stripe_id).each do |stripe_id, stripe_subscriptions|
        next unless stripe_id.present?
        total_cost = stripe_subscriptions.map(&:cost_in_pennies).sum
        begin
          stripe_charge = Stripe::Charge.create({
            amount:   total_cost,
            currency: "usd",
            customer: stripe_subscriptions.first.stripe_id
          })
        rescue Stripe::CardError => e
          stripe_charge = {failure_message: "Stripe Error: Failed to Charge: #{e}"}
        rescue StandardError => e
          stripe_charge = {failure_message: "Failed to Charge: #{e}"}
        end
        if stripe_charge.try(:status) == "succeeded"
          slack_message = "Charged Unlimited Subscriptions for #{user.email} at #{number_to_currency(total_cost/100.to_f)}."
          channel = Rails.env.production? ? "#purchases" : "#slack-testing"
          SlackNotifier.notify(slack_message, channel)

          stripe_subscriptions.each do |recurring_subscription|
            recurring_subscription.update(auto_renew: false)
            new_sub = user.recurring_subscriptions.create(athlete_id: recurring_subscription.athlete_id, auto_renew: true, cost_in_pennies: recurring_subscription.cost_in_pennies, stripe_id: recurring_subscription.stripe_id)
            unless new_sub.persisted?
              SlackNotifier.notify("Failed to create new sub: ```#{new_sub.try(:attributes)}\n#{new_sub.try(:errors).try(:full_messages)}```", "#server-errors")
            end
          end
        else
          stripe_subscriptions.each { |subscription| subscription.update(card_declined: true) }
          SlackNotifier.notify("There was an issue updating the subscription for #{user.email}\n```#{stripe_charge}```", "#server-errors")
        end
      end
    end
  end

  def monthly_plan_charges(params)
    Stripe.api_key = ENV['PKUT_STRIPE_SECRET_KEY']
    PurchasedPlanItem.assigned.auto_renew.inactive.available.group_by(&:user).each do |user, recurring_plan|
      recurring_plan.group_by(&:stripe_id).each do |stripe_id, plans|
        next unless stripe_id.present?
        stripe_error = nil

        total_cost = plans.map(&:cost_in_pennies).sum
        begin
          stripe_charge = Stripe::Charge.create({
            amount:   total_cost,
            currency: "usd",
            customer: stripe_id
          })
        rescue Stripe::CardError => e
          stripe_charge = { failure_message: "Stripe Error: Failed to Charge: #{e}" }
          stripe_error = e
        rescue StandardError => e
          stripe_charge = { failure_message: "Failed to Charge: #{e}" }
          stripe_error = e
        end
        if stripe_charge.try(:status) == "succeeded"
          slack_message = "Charged Plan Subscriptions for #{user.email} at #{number_to_currency(total_cost/100.to_f)}."
          channel = Rails.env.production? ? "#purchases" : "#slack-testing"
          SlackNotifier.notify(slack_message, channel)

          plans.each do |plan|
            plan.update(auto_renew: false)
            new_sub = current_user.purchased_plan_items.create(
              athlete_id: plan.athlete_id,
              stripe_id: plan.stripe_id,
              plan_item_id: plan.plan_item_id,
              cost_in_pennies: plan.cost_in_pennies,
              discount_items: plan.discount_items,
              free_items: plan.free_items,
            )
            unless new_sub.persisted?
              SlackNotifier.notify("Failed to create new sub: ```#{new_sub.try(:attributes)}\n#{new_sub.try(:errors).try(:full_messages)}```", "#server-errors")
            end
          end
        else
          plans.each { |subscription| subscription.update(card_declined: stripe_error) }
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
    return # Temporary while we figure out the AWS gems
    # return unless Rails.env.production?
    # s3 = AWS::S3.new
    # buckets = [s3.buckets["pkut-default"], s3.buckets["pkut-uploads"]]
    # buckets.each do |bucket|
    #   log_files = bucket.objects.with_prefix('logs')
    #   log_files.each do |log_file|
    #     file_body = log_file.read
    #     logit = AwsLogger.create(orginal_string: file_body)
    #     if logit.persisted? || logit.is_log_request?
    #       log_file.delete
    #     else
    #       unless logit.is_log_request?
    #         SlackNotifier.notify("Failed to delete file: \n#{log_file}:```#{file_body}```", "#server-errors")
    #       end
    #     end
    #   end
    # end
  end

  def minutes_from_now(seconds)
    Time.zone.now + (seconds * 60)
  end

  def days_from_now(seconds)
    Time.zone.now + (seconds * 60 * 60 * 24)
  end

  def weeks_from_now(seconds)
    Time.zone.now + (seconds * 60 * 60 * 24 * 7)
  end

  def minutes_ago(seconds)
    Time.zone.now - (seconds * 60)
  end

  def days_ago(seconds)
    Time.zone.now - (seconds * 60 * 60 * 24)
  end

end
