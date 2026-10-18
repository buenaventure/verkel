# frozen_string_literal: true

namespace :padded_names do
  desc 'strips whitespace around ingredient and diet names (dry run unless APPLY=1)'
  task cleanup: :environment do
    PaddedNameCleanup.new(apply: ENV['APPLY'] == '1').call
  end
end
