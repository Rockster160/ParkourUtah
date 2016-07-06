class MailEverybodyWorker
  include Sidekiq::Worker

  def perform
    User.all.each do |user|
      PartyMailerWorker.perform_async(user.email)
      sleep 1
    end
  end

end
