FactoryBot.define do
  factory :group do
    sequence(:name) { |n| "Gruppe #{n}" }
    association :packing_lane
  end
end
