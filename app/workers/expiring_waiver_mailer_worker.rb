class ExpiringWaiverMailerWorker
  include Sidekiq::Worker

  def perform(athlete_id)
    ApplicationMailer.expiring_waiver_mail(athlete_id).deliver_now
  end

end
