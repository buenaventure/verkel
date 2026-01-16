FactoryBot.define do
  factory :group do
    sequence(:name) { |n| "Gruppe #{n}" }
    packing_lane
  end
end
