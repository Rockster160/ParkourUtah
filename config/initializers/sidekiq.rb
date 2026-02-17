require 'sidekiq/web'
require 'sidekiq/cron/web'

redis_url = ENV.fetch('REDIS_URL', 'redis://localhost:6379/0')

Sidekiq.configure_server do |config|
  config.redis = { url: redis_url }
end

Sidekiq.configure_client do |config|
  config.redis = { url: redis_url }
end

# Only register cron jobs inside the Sidekiq server process
Sidekiq.configure_server do |config|
  config.on(:startup) do
    cron_jobs = [
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
  end
end
