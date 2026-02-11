Rails.application.routes.default_url_options[:host] = 'staging.parkourutah.com'
Rails.application.routes.default_url_options[:protocol] = 'http://'
Rails.application.routes.default_url_options[:port] = nil
Rails.application.configure do

  config.enable_reloading = false

  config.eager_load = true

  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = true

  config.action_cable.url = "ws://staging.parkourutah.com/cable"
  config.action_cable.allowed_request_origins = ["http://staging.parkourutah.com"]

  routes.default_url_options = { host: 'staging.parkourutah.com', protocol: 'http://', port: nil }
  config.action_mailer.default_url_options = { host: 'staging.parkourutah.com', protocol: 'http://', port: nil }
  config.action_mailer.asset_host = 'http://staging.parkourutah.com'
  ActionMailer::Base.delivery_method = :smtp
  # ActionMailer::Base.smtp_settings = {
  #   :address              => 'email-smtp.us-west-2.amazonaws.com',
  #   :port                 => 587,
  #   :user_name            => ENV['PKUT_AWS_EMAILNAME'],
  #   :password             => ENV['PKUT_AWS_EMAIL_PASS'],
  #   :authentication       => :plain,
  #   :enable_starttls_auto => true,
  #   :openssl_verify_mode  => 'none'
  # }
  config.action_mailer.raise_delivery_errors = true
  config.action_mailer.perform_deliveries = true

  config.active_storage.service = :amazon

  # Compress JavaScripts and CSS.
  config.assets.js_compressor = :terser
  # config.assets.css_compressor = :sass

  # Do not fallback to assets pipeline if a precompiled asset is missed.
  config.public_file_server.enabled = false
  config.assets.compile = false
  config.assets.digest = true

  # Asset digests allow you to set far-future HTTP expiration dates on all assets,
  # yet still be able to expire them through the digest params.

  # `config.assets.precompile` and `config.assets.version` have moved to config/initializers/assets.rb

  # Specifies the header that your server uses for sending files.
  # config.action_dispatch.x_sendfile_header = 'X-Sendfile' # for Apache
  # config.action_dispatch.x_sendfile_header = 'X-Accel-Redirect' # for NGINX

  # Force all access to the app over SSL, use Strict-Transport-Security, and use secure cookies.
  # config.force_ssl = true

  # Use the lowest log level to ensure availability of diagnostic information
  # when problems arise.
  config.log_level = :info
  config.log_formatter = ::Logger::Formatter.new

  # config.log_formatter = ::Logger::Formatter.new

  # Prepend all log lines with the following tags.
  # config.log_tags = [ :subdomain, :uuid ]

  # Use a different logger for distributed setups.
  # config.logger = ActiveSupport::TaggedLogging.new(SyslogLogger.new)

  # Use a different cache store in staging.
  # config.cache_store = :mem_cache_store

  # Enable serving of images, stylesheets, and JavaScripts from an asset server.
  # config.action_controller.asset_host = 'http://assets.example.com'

  # Ignore bad email addresses and do not raise email delivery errors.
  # Set this to true and configure the email server for immediate delivery to raise delivery errors.
  # config.action_mailer.raise_delivery_errors = false

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation cannot be found).
  config.i18n.fallbacks = true

  # Send deprecation notices to registered listeners.
  config.active_support.deprecation = :notify

  # Do not dump schema after migrations.
  config.active_record.dump_schema_after_migration = false
end

require "#{Rails.root}/lib/custom_notifier"
Rails.application.config.middleware.use ExceptionNotification::Rack, custom: {}
