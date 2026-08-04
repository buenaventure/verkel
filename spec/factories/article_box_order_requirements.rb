# frozen_string_literal: true

FactoryBot.define do
  factory :article_box_order_requirement do
    article
    box
    quantity { 5 }
    stock { 0 }
    ordered { 0 }
  end
end
