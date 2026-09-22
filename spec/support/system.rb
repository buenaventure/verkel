# frozen_string_literal: true

require 'capybara/rspec'
require 'selenium-webdriver'

Capybara.register_driver :headless_chrome do |app|
  options = Selenium::WebDriver::Chrome::Options.new
  options.add_argument('--headless=new')
  options.add_argument('--window-size=1400,900')
  options.add_argument('--no-sandbox')
  options.add_argument('--disable-dev-shm-usage')
  # Keeps the console messages readable for JavascriptErrors.
  options.logging_prefs = { browser: 'ALL' }

  Capybara::Selenium::Driver.new(app, browser: :chrome, options:)
end

RSpec.configure do |config|
  config.before(:each, type: :system) { driven_by :headless_chrome }
end
