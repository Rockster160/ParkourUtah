class NewAthleteNotificationMailerWorker
  include Sidekiq::Worker

  def perform(text)
    NewAthleteNotificationMailer.new_athlete_notification_mail(text).deliver_now
  end

end
