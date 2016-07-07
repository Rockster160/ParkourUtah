class SendTempMailToAllUsersWorker
  include Sidekiq::Worker
  sidekiq_options retry: false

  def perform
    count = User.count
    User.all.each do |u|
      WelcomeMailer.delay.temp_mail(u.email).deliver
      puts "Emailed: #{u.email}. #{count -= 1} users to go."
      sleep 5
    end
  end

end
