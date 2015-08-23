class SmsMailerWorker
  include Sidekiq::Worker

  def perform(num, msg)
    api = Twilio::REST::Client.new(ENV['PKUT_TWILIO_ACCOUNT_SID'], ENV['PKUT_TWILIO_AUTH_TOKEN'])
    messages = msg.scan(/.{1,800}m/)
    messages.each do |message|
      api.account.messages.create(
        body: message,
        to: num,
        from: "+17405714304"
      )
    end
  end
end
