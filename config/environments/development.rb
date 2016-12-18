Rails.application.configure do

  config.cache_classes = false

  config.eager_load = false

  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false

  config.action_mailer.default_url_options   = { :host => 'localhost:7545' }
  # ActionMailer::Base.delivery_method = :smtp
  # ActionMailer::Base.smtp_settings = {
  #   :address              => 'email-smtp.us-west-2.amazonaws.com',
  #   :port                 => 587,
  #   :user_name            => ENV['PKUT_AWS_EMAILNAME'],
  #   :password             => ENV['PKUT_AWS_EMAIL_PASS'],
  #   :authentication       => :plain,
  #   :enable_starttls_auto => true
  # }
  config.action_mailer.raise_delivery_errors = false
  config.action_mailer.perform_deliveries = false

  Paperclip.options[:command_path] = "/usr/local/bin/"
  config.paperclip_defaults = {
    :storage => :s3,
    :s3_credentials => {
      :bucket => ENV['PKUT_S3_BUCKET_NAME'],
      :access_key_id => ENV['PKUT_AWS_ACCESS_KEY_ID'],
      :secret_access_key => ENV['PKUT_AWS_SECRET_ACCESS_KEY']
    }
  }

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

  # Adds additional error checking when serving assets at runtime.
  # Checks for improperly declared sprockets dependencies.
  # Raises helpful error messages.
  config.assets.raise_runtime_errors = true

  # Raises error for missing translations
  # config.action_view.raise_on_missing_translations = true
end

require "#{Rails.root}/lib/custom_notifier"
Rails.application.config.middleware.use ExceptionNotification::Rack, custom: {}
