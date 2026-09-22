# frozen_string_literal: true

source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '4.0.7'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'bootsnap', '>= 1.4.4', require: false
gem 'cancancan'
gem 'combine_pdf'
gem 'cssbundling-rails'
gem 'csv-importer'
gem 'devise'
gem 'devise-i18n'
gem 'hotwire-rails', '~> 0.1'
gem 'httparty'
gem 'image_processing', '~> 2.1'
gem 'jbuilder', '~> 2.15'
gem 'jsbundling-rails'
# Rails 8.1.3.1 calls JSON.parse with a positional options hash, which json 3
# rejects, so every request that reads the session cookie raises an
# ArgumentError. Fixed on rails/rails main and 8-1-stable; drop this pin once
# the Rails release we run includes that fix (next 8.1 patch release, or 8.2).
gem 'json', '< 3'
gem 'kramdown', '~> 2.5'
gem 'kramdown-parser-gfm', '~> 1.0'
gem 'matrix'
gem 'memery'
gem 'nokogiri'
gem 'ostruct'
gem 'pg'
gem 'prawn'
gem 'prawn-table'
gem 'puma', '~> 8.0'
gem 'rails', '~> 8.1.0'
gem 'rails-i18n', '~> 8.1.0'
gem 'safe_yaml'
gem 'scenic'
gem 'simple_form'
gem 'sprockets-rails'
gem 'tzinfo-data', platforms: %i[mingw mswin x64_mingw jruby]

# Use Redis adapter to run Action Cable in production
# gem 'redis', '~> 4.0'
# Use Active Model has_secure_password
# gem 'bcrypt', '~> 3.1.7'

group :development, :test do
  gem 'dotenv-rails'
  gem 'factory_bot_rails'
  gem 'rspec-rails', '~> 8.0.4'
end

group :development do
  gem 'bundle_update_interactive'
  gem 'debug', '>= 1.0.0'
  gem 'listen', '~> 3.10'
  gem 'rack-mini-profiler', '~> 5.0'
  gem 'rubocop', require: false
  gem 'rubocop-factory_bot', require: false
  gem 'rubocop-performance', require: false
  gem 'rubocop-rails', require: false
  gem 'rubocop-rspec', require: false
  gem 'rubocop-rspec_rails', require: false
  gem 'solargraph'
  gem 'spring'
  gem 'web-console', '>= 4.1.0'
end

group :test do
  gem 'capybara', '>= 3.26'
  gem 'selenium-webdriver'
  gem 'shoulda-matchers', '~> 8.0'
end
