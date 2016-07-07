class SendTempMailToAllUsersWorker
  include Sidekiq::Worker

  def perform
    User.all.each do |u|
      WelcomeMailer.temp_mail(u.email).deliver_now
      sleep 5
    end
  end

end
