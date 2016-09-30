class SummaryMailerWorker
  include Sidekiq::Worker

  def perform(summary)
    return true unless Rails.env.production?
    SummaryMailer.summary_mail(summary).deliver_now
  end

end
