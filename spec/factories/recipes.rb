# frozen_string_literal: true

FactoryBot.define do
  factory :recipe do
    sequence(:name) { |n| "Rezept #{n}" }
    servings { 4 }
    content { "**500 g Nudeln**\n\n**1 kg Tomaten**" }
  end
end
