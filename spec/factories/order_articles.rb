# frozen_string_literal: true

FactoryBot.define do
  factory :order_article do
    order
    article { association :article, supplier: order.supplier, unit: 'g', packing_type: :piece, quantity: 500 }
    quantity_ordered { 10 }
    quantity_delivered { 0 }
  end
end
