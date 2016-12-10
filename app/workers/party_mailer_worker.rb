class PartyMailerWorker
  include Sidekiq::Worker

  def perform(mail)
    ApplicationMailer.party_mail(mail).deliver_now
  end

end
