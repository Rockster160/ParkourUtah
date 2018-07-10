class SmsMailerWorker
  include Sidekiq::Worker
  sidekiq_options :retry => false

  def perform(num, msg)
    if Rails.env.production?
      api = Twilio::REST::Client.new(ENV['PKUT_TWILIO_ACCOUNT_SID'], ENV['PKUT_TWILIO_AUTH_TOKEN'])
      message = "Hi! This is the new Parkour Utah contact number. Feel free to message or call us back with any questions!\n"
      messages = msg.scan(/.{1,800}/m)
      messages.each do |message|
        begin
          api.account.messages.create(
            body: message,
            to: num,
            from: "+18444355867"
          )
        rescue Twilio::REST::RequestError => e
          m = Message.where(phone_number: num, body: msg).last
          if e.message == "The message From/To pair violates a blacklist rule."
            m.error!("Blacklisted")
            if user = User.find_by_phone_number(num)
              user.update(can_receive_sms: false)
            else
              SmsMailerWorker.perform_async('+13852599640', "No user found!! Number: #{num}")
            end
            return true
          else
            m.error!(e.message)
            SmsMailerWorker.perform_async('+13852599640', "SMS failed: #{num}: #{e.message}")
          end
        end
      end
    else
      puts "\e[31m DEV: Text Message to #{num}:\n#{msg} \e[0m"
    end
  end

end
