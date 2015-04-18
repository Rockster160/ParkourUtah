class SendWelcomeEmailWorker
  include Sidekiq::Worker

  def perform(email)
    WelcomeMailer.welcome_mail(email).deliver_now
  end

end
