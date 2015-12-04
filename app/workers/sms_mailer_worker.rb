class SmsMailerWorker
  include Sidekiq::Worker
  sidekiq_options :retry => false

  def perform(num, msg)
    api = Twilio::REST::Client.new(ENV['PKUT_TWILIO_ACCOUNT_SID'], ENV['PKUT_TWILIO_AUTH_TOKEN'])
    messages = msg.scan(/.{1,800}/m)
    messages.each do |message|
      begin
        api.account.messages.create(
          body: message,
          to: num,
          from: "+17405714304"
        )
      rescue Twilio::REST::RequestError => e
        if e.message == "The message From/To pair violates a blacklist rule."
          if user = User.find_by_phone_number(num)
            user.notifications.update(sms_receivable: false)
          else
            SmsMailerWorker.perform_async('+13852599640', "No user found!! Number: #{num}")
          end
          return true
        else
          SmsMailerWorker.perform_async('+13852599640', "SMS failed: #{num}: #{e.message}")
        end
      end
    end
  end
end
