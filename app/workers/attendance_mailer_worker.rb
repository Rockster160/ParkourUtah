class AttendanceMailerWorker
  include Sidekiq::Worker

  def perform(params)
    ClassSummaryMailer.summary_mail(params).deliver_now
  end

end
