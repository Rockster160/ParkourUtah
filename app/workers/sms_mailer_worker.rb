class SmsMailerWorker
  include Sidekiq::Worker

  def perform(num, msg)
    api = Twilio::REST::Client.new(ENV['PKUT_TWILIO_ACCOUNT_SID'], ENV['PKUT_TWILIO_AUTH_TOKEN'])
    api.account.messages.create(
      body: msg,
      to: num,
      from: "+17405714304"
    )
  end
end
