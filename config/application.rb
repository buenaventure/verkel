require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Speiseplaner
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.0

    # we use turbo so disable old remote forms
    config.action_view.form_with_generates_remote_forms = false

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    config.time_zone = 'Europe/Berlin'
    config.i18n.available_locales = [:de]
    config.i18n.default_locale = :de
    # config.eager_load_paths << Rails.root.join("extras")

    config.estimation = false
    config.estimated_participants = 4000

    config.kramdown_options = {
      input: 'GFM',
      hard_wrap: false
    }
    config.lama_api = {}
  end
end
