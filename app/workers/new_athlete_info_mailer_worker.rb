class NewAthleteInfoMailerWorker
  include Sidekiq::Worker

  def perform(athlete_ids)
    NewAthleteInfoMailer.new_athlete_info_mail(athlete_ids).deliver_now
  end

end
