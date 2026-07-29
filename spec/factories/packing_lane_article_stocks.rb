FactoryBot.define do
  factory :packing_lane_article_stock do
    packing_lane
    article
    box
    quantity { 1 }
  end
end
