class SmsMailerWorker
  include Sidekiq::Worker
  include ApplicationHelper
  sidekiq_options :retry => false

  # Twilio's "recipient has opted out / From-To pair violates a blacklist rule" code.
  BLACKLIST_ERROR_CODE = 21610
  ALERT_NUMBER = '+13852599640'
  PKUT_NUMBER = '+18444355867'

  def perform(num, msg)
    unless Rails.env.production?
      puts "\e[31m DEV: Text Message to #{num}:\n#{msg} \e[0m"
      return
    end

    api = Twilio::REST::Client.new(ENV['PKUT_TWILIO_ACCOUNT_SID'], ENV['PKUT_TWILIO_AUTH_TOKEN'])
    msg.scan(/.{1,800}/m).each do |message|
      begin
        api.accounts.client.messages.create(
          body: message,
          to: num,
          from: PKUT_NUMBER
        )
      rescue Twilio::REST::RestError => e
        handle_failure(num, msg, e)
        return true if blacklisted?(e)
      end
    end
  end

  private

  def blacklisted?(error)
    error.code == BLACKLIST_ERROR_CODE || error.message.to_s.include?("blacklist")
  end

  def handle_failure(num, msg, error)
    if blacklisted?(error)
      last_message_to(num, msg).try(:error!, "Blacklisted")
      if user = User.by_phone_number(num).first
        user.update(can_receive_sms: false)
      else
        alert_support("No user found!! Number: #{num}", num)
      end
    else
      last_message_to(num, msg).try(:error!, error.message)
      alert_support("SMS failed: #{num}: #{error.message}", num)
    end
  end

  # Never alert about a failure to deliver to the alert number itself- that
  # would enqueue another failing job, and another, forever.
  def alert_support(body, failed_number)
    return if strip_phone_number(failed_number) == strip_phone_number(ALERT_NUMBER)
    SmsMailerWorker.perform_async(ALERT_NUMBER, body)
  end

  def last_message_to(num, msg)
    stripped_number = strip_phone_number(num)
    return if stripped_number.blank?
    chat_room = ChatRoom.text.find_by(name: stripped_number)
    return if chat_room.nil?
    chat_room.messages.where(body: msg).order(:created_at).last
  end

end
