class PartyMailerWorker
  include Sidekiq::Worker

  def perform(mail)
    ContactMailer.party_mail(mail).deliver_now
  end

end
