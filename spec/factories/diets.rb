# frozen_string_literal: true

FactoryBot.define do
  factory :diet do
    sequence(:name) { |n| "Ernährungsweise #{n}" }
  end
end
