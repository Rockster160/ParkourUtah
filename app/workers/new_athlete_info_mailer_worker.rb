class NewAthleteInfoMailerWorker
  include Sidekiq::Worker

  def perform(athlete_id)
    NewAthleteInfoMailer.new_athlete_info_mail(athlete_id).deliver_now
  end

end
