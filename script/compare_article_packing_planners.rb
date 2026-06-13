# frozen_string_literal: true

# Run the same random scenarios through the legacy and current planners and
# print the first plan difference.
#
# Usage:
#   RAILS_ENV=test bin/rails runner script/compare_article_packing_planners.rb
#   SEED=42 RAILS_ENV=test bin/rails runner script/compare_article_packing_planners.rb 100

abort('Run in test environment: RAILS_ENV=test') unless Rails.env.test?

require 'factory_bot'
FactoryBot.find_definitions unless FactoryBot.factories.any?

trials = ARGV.fetch(0, 25).to_i
seed = ENV.fetch('SEED', Random.new_seed).to_i

ArticlePackingPlannerBattleTest.compare(trials:, seed:)
