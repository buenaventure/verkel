# frozen_string_literal: true

FactoryBot.define do
  factory :hoard do
    article
    quantity { 5 }
    missing_quantity { 5 }
    add_attribute(:until) { 1.week.from_now }
  end
end
