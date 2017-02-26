class NewAthleteInfoMailerWorker
  include Sidekiq::Worker

  def perform(fast_pass_ids)
    ApplicationMailer.new_athlete_info_mail(fast_pass_ids).deliver_now
  end

end
