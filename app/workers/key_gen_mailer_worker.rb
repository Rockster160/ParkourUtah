class KeyGenMailerWorker
  include Sidekiq::Worker

  def perform(keys)
    KeyGenMailer.key_gen_mail(keys).deliver_now
  end

end
