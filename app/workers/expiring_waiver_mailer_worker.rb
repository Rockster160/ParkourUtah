class ExpiringWaiverMailerWorker
  include Sidekiq::Worker

  def perform(fast_pass_id)
    ApplicationMailer.expiring_waiver_mail(fast_pass_id).deliver_now
  end

end
