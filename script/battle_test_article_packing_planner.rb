# frozen_string_literal: true

# Randomised property checks for ArticlePackingPlanner.
#
# Usage:
#   RAILS_ENV=test bin/rails runner script/battle_test_article_packing_planner.rb
#   RAILS_ENV=test bin/rails runner script/battle_test_article_packing_planner.rb 50
#   SEED=42 RAILS_ENV=test bin/rails runner script/battle_test_article_packing_planner.rb 100
#
# Each trial builds a random scenario inside a rolled-back database transaction,
# runs the planner (twice for idempotency), and verifies planner invariants.
# See lib/article_packing_planner_battle_test.rb for the full invariant list.

abort('Run in test environment: RAILS_ENV=test') unless Rails.env.test?

require 'factory_bot'
FactoryBot.find_definitions unless FactoryBot.factories.any?

trials = ARGV.fetch(0, 25).to_i
seed = ENV.fetch('SEED', Random.new_seed).to_i
verbose = ENV['VERBOSE'] == '1'
planner_class =
  case ENV.fetch('PLANNER', 'current')
  when 'legacy' then ArticlePackingPlannerLegacy
  when 'current' then ArticlePackingPlanner
  else abort("Unknown PLANNER=#{ENV['PLANNER'].inspect} (use legacy or current)")
  end
skip_invariants =
  if ENV.key?('SKIP_INVARIANTS')
    ENV['SKIP_INVARIANTS'].split(',').map(&:strip)
  elsif planner_class == ArticlePackingPlannerLegacy
    %w[8 17]
  else
    []
  end

ArticlePackingPlannerBattleTest.run(trials:, seed:, verbose:, planner_class:, skip_invariants:)
