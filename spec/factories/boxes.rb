FactoryBot.define do
  factory :box do
    datetime { Time.zone.now }
    box_type { :default }
    status { :stocked }

    trait :picked do
      status { :picked }
    end

    trait :packed do
      status { :packed }
    end
  end
end
