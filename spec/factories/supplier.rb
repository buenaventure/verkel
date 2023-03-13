FactoryBot.define do
  factory :supplier do
    sequence(:name) { |n| "Supplier #{n}" }
  end
end
