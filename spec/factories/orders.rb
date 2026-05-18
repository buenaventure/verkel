# frozen_string_literal: true

FactoryBot.define do
  factory :order do
    supplier
    state { :planned }
    coverage { (1.week.from_now.beginning_of_day..2.weeks.from_now.end_of_day) }

    trait :ordered do
      state { :ordered }
    end

    trait :delivered do
      state { :delivered }
    end

    trait :stored do
      state { :stored }
    end

    trait :canceled do
      state { :canceled }
    end
  end
end
