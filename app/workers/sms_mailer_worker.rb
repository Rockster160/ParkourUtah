class SmsMailerWorker
  include Sidekiq::Worker
  # ::SMSMailerWorker.perform_async('It worked!', ['3852599640'])

  def perform(msg, nums)
    api = Twilio::REST::Client.new(ENV['PKUT_TWILIO_ACCOUNT_SID'], ENV['PKUT_TWILIO_AUTH_TOKEN'])

    nums.each do |num|
      api.account.messages.create(
        body: msg,
        to: num,
        from: "+17405714304"
      )
    end
  end
end
