RSpec.configure do |config|
  config.include Devise::Test::IntegrationHelpers, type: :request
  config.include Warden::Test::Helpers, type: :system

  config.after(:each, type: :system) { Warden.test_reset! }
end
