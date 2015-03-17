class SummaryMailerWorker
  include Sidekiq::Worker

  def perform(summary)
    SummaryMailer.summary_mail(summary).deliver_now
  end

end
