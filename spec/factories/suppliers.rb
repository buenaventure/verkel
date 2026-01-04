FactoryBot.define do
  factory :supplier do
    sequence(:name) { |n| "Lieferant #{n}" }
    delivery_time { 24 }
  end
end
