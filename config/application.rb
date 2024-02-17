require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Verkel
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.1

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w(assets tasks))

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    config.time_zone = 'Europe/Berlin'
    config.i18n.available_locales = [:de]
    config.i18n.default_locale = :de
    # config.eager_load_paths << Rails.root.join("extras")
    config.active_record.schema_format = :sql

    config.estimation = false
    config.estimated_participants = 4000

    config.lama_sync = false

    config.kramdown_options = {
      input: 'GFM',
      hard_wrap: false
    }
  end
end
