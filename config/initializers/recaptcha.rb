Recaptcha.configure do |config|
  config.site_key = ENV["PKUT_RECAPTCHA_PUBLIC"]
  config.secret_key = ENV["PKUT_RECAPTCHA_PRIVATE"]
end
