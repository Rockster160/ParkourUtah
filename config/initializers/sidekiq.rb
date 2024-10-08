require 'sidekiq/web'

Sidekiq::Extensions.enable_delay!

config = {
  host: Redis.current.client.host,
  port: Redis.current.client.port,
  password: Redis.current.client.password,
  db: (!!defined?(REDIS_CONFIG) ? REDIS_CONFIG[:db_worker] : Redis.current.client.db),
  namespace: "sidekiq_#{Rails.application.class.name}_#{Rails.env}".downcase
}

Sidekiq.configure_server { |c| c.redis = config }
Sidekiq.configure_client { |c| c.redis = config }

# To reset Queues in case any changed:
cron_jobs = [
  # arg keys are used to call the method, NOT the cron name.
  { name: "uptime_ping",                  cron: "*/30 * * * *", class: "ScheduleWorker", args: { uptime_ping: nil } },
  { name: "post_to_custom_logger",        cron: "*/5 * * * *",  class: "ScheduleWorker", args: { post_to_custom_logger: nil } },
  { name: "send_class_text",              cron: "*/30 * * * *", class: "ScheduleWorker", args: { send_class_text: nil } },
  { name: "subscribe_new_user",           cron: "*/30 * * * *", class: "ScheduleWorker", args: { subscribe_new_user: nil } },
  { name: "send_summary_daily",           cron: "10 21 * * *",  class: "ScheduleWorker", args: { send_summary: {scope: 'day'} } },
  { name: "waiver_checks",                cron: "30 9 * * *",   class: "ScheduleWorker", args: { waiver_checks: nil } },
  { name: "remind_recurring_payments",    cron: "30 10 * * *",  class: "ScheduleWorker", args: { remind_recurring_payments: nil } },
  { name: "monthly_subscription_charges", cron: "0 7 * * *",    class: "ScheduleWorker", args: { monthly_subscription_charges: nil } },
  { name: "monthly_plan_charges",         cron: "0 7 * * *",    class: "ScheduleWorker", args: { monthly_plan_charges: nil } },
  { name: "send_summary_monthly",         cron: "0 7 1 * *",    class: "ScheduleWorker", args: { send_summary: {scope: 'month'} } },
  { name: "pull_logs_from_s3",            cron: "0 * * * *",    class: "ScheduleWorker", args: { pull_logs_from_s3: {} } }
]
Sidekiq::Cron::Job.load_from_array!(cron_jobs)
