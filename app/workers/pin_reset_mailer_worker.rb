class PinResetMailerWorker
  include Sidekiq::Worker

  def perform(fast_pass_id)
    ApplicationMailer.pin_reset_mail(fast_pass_id).deliver_now
  end

end
