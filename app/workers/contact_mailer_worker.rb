class ContactMailerWorker
  include Sidekiq::Worker

  def perform(msg)
    ApplicationMailer.help_mail(msg).deliver_now
  end

end
