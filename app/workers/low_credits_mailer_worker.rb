class LowCreditsMailerWorker
  include Sidekiq::Worker

  def perform(user_id)
    LowCreditsMailer.low_credits_mail(user_id).deliver_now
  end

end