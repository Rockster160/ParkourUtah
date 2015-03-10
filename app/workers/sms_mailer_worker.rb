class SmsMailerWorker
  include Sidekiq::Worker

  def perform(msg, nums)
    api = GoogleVoice::Api.new(ENV['PKUT_GOOGLE_VOICE_USERNAME'], ENV['PKUT_GOOGLE_VOICE_PASSWORD'])

    nums.each do |num|
      api.sms(num, msg)
    end
  end
end
