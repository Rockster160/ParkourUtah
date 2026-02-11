require_relative 'boot'

require 'rails/all'
require 'sprockets/railtie'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module ParkourUtah
  class Application < Rails::Application
    config.load_defaults 8.0

    config.autoloader = :zeitwerk
    Rails.autoloaders.main.inflector.inflect("json_wrapper" => "JSONWrapper")

    config.public_file_server.enabled = false
    config.assets.initialize_on_precompile = true
    config.assets.paths << Rails.root.join("app", "assets", "fonts", "**", "*")
    config.autoload_paths += %W(#{config.root}/lib)
    config.eager_load_paths += %W(#{config.root}/lib)
    config.exceptions_app = self.routes

    config.time_zone = 'Mountain Time (US & Canada)'

    config.assets.quiet = true
  end
end
