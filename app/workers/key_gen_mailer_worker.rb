class KeyGenMailerWorker
  include Sidekiq::Worker

  def perform(keys, topic)
    KeyGenMailer.key_gen_mail(keys, topic).deliver_now
  end

end
