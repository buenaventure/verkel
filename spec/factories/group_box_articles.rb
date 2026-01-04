FactoryBot.define do
  factory :group_box_article do
    association :group
    association :box
    association :article
    quantity { 1 }
  end
end
