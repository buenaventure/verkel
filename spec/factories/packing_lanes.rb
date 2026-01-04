FactoryBot.define do
  factory :packing_lane do
    sequence(:name) { |n| "Packstraße #{n}" }
  end
end
