FactoryBot.define do
  factory :article do
    ingredient
    supplier
    quantity { 1 }
    unit { 'g' }
  end
end
