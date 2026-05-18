# frozen_string_literal: true

FactoryBot.define do
  factory :group_change do
    participant
    group
    timeframe { (1.week.from_now.beginning_of_day..2.weeks.from_now.beginning_of_day) }
  end
end
