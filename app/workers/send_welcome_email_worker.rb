class SendWelcomeEmailWorker
  include Sidekiq::Worker

  def perform(email)
    ApplicationMailer.welcome_mail(email).deliver_now
  end

end
