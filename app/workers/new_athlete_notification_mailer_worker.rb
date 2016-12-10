class NewAthleteNotificationMailerWorker
  include Sidekiq::Worker

  def perform(athlete_ids)
    ApplicationMailer.new_athlete_notification_mail(athlete_ids).deliver_now
  end

end
