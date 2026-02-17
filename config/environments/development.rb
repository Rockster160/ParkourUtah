Rails.application.routes.default_url_options[:host] = 'localhost'
Rails.application.routes.default_url_options[:protocol] = 'http://'
Rails.application.routes.default_url_options[:port] = '7545'
Rails.application.configure do

  config.enable_reloading = true

  config.eager_load = false

  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false

  config.action_mailer.default_url_options   = { :host => 'localhost:7545' }

  config.action_cable.url = "ws://localhost:7545/cable"
  config.action_cable.allowed_request_origins = ["http://localhost:7545"]

  ActionMailer::Base.delivery_method = :smtp
  ActionMailer::Base.smtp_settings = {
    :address              => 'email-smtp.us-west-2.amazonaws.com',
    :port                 => 587,
    :user_name            => ENV['PKUT_AWS_EMAILNAME'],
    :password             => ENV['PKUT_AWS_EMAIL_PASS'],
    :authentication       => :plain,
    :enable_starttls_auto => true
  }
  config.action_mailer.raise_delivery_errors = false
  config.action_mailer.perform_deliveries = false

  config.active_storage.service = :amazon

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log

  # Raise an error on page load if there are pending migrations.
  config.active_record.migration_error = :page_load

  # Debug mode disables concatenation and preprocessing of assets.
  # This option may cause significant delays in view rendering with a large
  # number of complex assets.
  config.assets.debug = true

  # Asset digests allow you to set far-future HTTP expiration dates on all assets,
  # yet still be able to expire them through the digest params.
  config.assets.digest = true

  # Raises error for missing translations
  # config.action_view.raise_on_missing_translations = true
end
