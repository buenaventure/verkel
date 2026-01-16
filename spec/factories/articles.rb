FactoryBot.define do
  factory :article do
    ingredient
    supplier
    name { '' }
    quantity { 1 }
    unit { 'pcs' }
    packing_type { :piece }
    needs_cooling { false }
    stock { 0 }
    priority { 0 }

    trait :bulk do
      packing_type { :bulk }
      quantity { 1 }
      unit { 'g' }
    end

    trait :piece do
      packing_type { :piece }
      quantity { 500 }
      unit { 'pcs' }
    end

    trait :needs_cooling do
      needs_cooling { true }
    end
  end
end
