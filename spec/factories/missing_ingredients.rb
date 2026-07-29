FactoryBot.define do
  factory :missing_ingredient do
    group
    box
    ingredient
    quantity { 1 }
    unit { 'g' }
  end
end
