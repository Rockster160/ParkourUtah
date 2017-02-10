require 'sidekiq/web'

config = {
  host: Redis.current.client.host,
  port: Redis.current.client.port,
  password: Redis.current.client.password,
  db: (!!defined?(REDIS_CONFIG) ? REDIS_CONFIG[:db_worker] : Redis.current.client.db),
  namespace: "sidekiq_#{Rails.application.class.parent_name}_#{Rails.env}".downcase
}

Sidekiq.configure_server { |c| c.redis = config }
Sidekiq.configure_client { |c| c.redis = config }

# To reset Queues in case any changed:
# Sidekiq::Cron::Job.destroy_all!
Sidekiq::Cron::Job.create(name: "post_to_custom_logger", cron: "*/5 * * * *", class: "ScheduleWorker", args: {post_to_custom_logger: nil})
Sidekiq::Cron::Job.create(name: "send_class_text", cron: "0 * * * *", class: "ScheduleWorker", args: {send_class_text: nil})
Sidekiq::Cron::Job.create(name: "send_summary", cron: "40 21 * * *", class: "ScheduleWorker", args: {send_summary: {start_date_days_ago: 1}})
Sidekiq::Cron::Job.create(name: "waiver_checks", cron: "30 9 * * *", class: "ScheduleWorker", args: {waiver_checks: nil})
Sidekiq::Cron::Job.create(name: "remind_recurring_payments", cron: "30 10 * * *", class: "ScheduleWorker", args: {remind_recurring_payments: nil})
Sidekiq::Cron::Job.create(name: "monthly_subscription_charges", cron: "0 7 * * *", class: "ScheduleWorker", args: {monthly_subscription_charges: nil})
Sidekiq::Cron::Job.create(name: "send_summary_weekly", cron: "30 21 * * 6", class: "ScheduleWorker", args: {send_summary: {start_date_days_ago: 7}})
