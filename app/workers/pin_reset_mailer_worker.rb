class PinResetMailerWorker
  include Sidekiq::Worker

  def perform(athlete_id)
    ApplicationMailer.pin_reset_mail(athlete_id).deliver_now
  end

end
