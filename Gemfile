source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '3.1.2'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 7.0.0'
# Use postgres as the database for Active Record
gem 'pg'
# Use Puma as the app server
gem 'puma', '~> 5.0'
# Use SCSS for stylesheets
gem 'sass-rails', '>= 6'
# Transpile app-like JavaScript. Read more: https://github.com/rails/webpacker
gem 'webpacker', '~> 5.0'
gem 'hotwire-rails' , '~> 0.1'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.7'
# Use Redis adapter to run Action Cable in production
# gem 'redis', '~> 4.0'
# Use Active Model has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Use Active Storage variant
# gem 'image_processing', '~> 1.2'

# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap', '>= 1.4.4', require: false

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug', platforms: [:mri, :mingw, :x64_mingw]
  gem 'dotenv-rails'
  gem 'rspec-rails', '~> 5.0.0'
end

group :development do
  # Access an interactive console on exception pages or by calling 'console' anywhere in the code.
  gem 'web-console', '>= 4.1.0'
  # Display performance information such as SQL time and flame graphs for each request in your browser.
  # Can be configured to work on production as well see: https://github.com/MiniProfiler/rack-mini-profiler/blob/master/README.md
  gem 'rack-mini-profiler', '~> 2.0'
  gem 'listen', '~> 3.3'
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'
  gem 'pry'
  gem 'pry-byebug'

  gem 'capistrano',         require: false
  gem 'capistrano3-puma',   require: false
  gem 'capistrano-bundler', require: false
  gem 'capistrano-rails',   require: false
  gem 'capistrano-rbenv',   require: false

  gem 'ed25519', '>= 1.2', '< 2.0' # for ed25519 keys
  gem 'bcrypt_pbkdf', '>= 1.0', '< 2.0'

  # both may be removed when a new version of net-scp is released, which allows net-ssh > 7
  gem 'net-ssh', '~> 7.0.1'
  gem 'net-scp', git: 'https://github.com/net-ssh/net-scp.git'

  gem 'rubocop'
  gem 'solargraph'
end

group :test do
  # Adds support for Capybara system testing and selenium driver
  gem 'capybara', '>= 3.26'
  gem 'selenium-webdriver'
  # Easy installation and use of web drivers to run system tests with browsers
  gem 'webdrivers'
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]

gem 'cancancan'
gem 'devise'
gem 'devise-i18n'
gem 'httparty'
gem 'image_processing', '~> 1.2'
gem 'kramdown', '~> 2.3'
gem 'kramdown-parser-gfm', '~> 1.0'
gem 'matrix'
gem 'nokogiri'
gem 'prawn'
gem 'prawn-table'
gem 'rails-i18n', '~> 7.0.0'
gem 'roo', '~> 2.8.0', require: false
gem 'safe_yaml'
gem 'scenic'
gem 'simple_form'
gem 'combine_pdf'
