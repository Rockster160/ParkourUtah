class WeeklySummaryMailerWorker
  include Sidekiq::Worker

  def perform(summary)
    WeeklyClassSummaryMailer.weekly_summary_mail(summary).deliver_now
  end

end
