Recaptcha.configure do |config|
  config.public_key = ENV["PKUT_RECAPTCHA_PUBLIC"]
  config.private_key = ENV["PKUT_RECAPTCHA_PRIVATE"]
end
