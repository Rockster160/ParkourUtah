class BatchEmailerWorker
  include Sidekiq::Worker

  def perform(subject, body)
    User.joins(:notifications).where(notifications: {email_newsletter: true}).each do |user|
      puts "Emailing #{user.email}"
      ContactMailer.email(user.email, subject, body).deliver_now
      sleep 0.1
    end
  end

end
