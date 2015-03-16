class ContactMailerWorker
  include Sidekiq::Worker

  def perform(msg)
    ContactMailer.help_mail(msg).deliver_now
  end

end
