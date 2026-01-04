FactoryBot.define do
  factory :ingredient do
    sequence(:name) { |n| "Zutat #{n}" }
    box_type { :default }
    uses_hunger_factor { false }
    on_demand { false }
  end
end
