# frozen_string_literal: true

FactoryBot.define do
  factory :meal do
    recipe
    sequence(:name) { |n| "Mahlzeit #{n}" }
    datetime { 1.week.from_now.change(hour: 12) }
  end
end
