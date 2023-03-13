FactoryBot.define do
  factory :group do
    sequence(:name) { |n| "Unit #{n}" }
  end
end
