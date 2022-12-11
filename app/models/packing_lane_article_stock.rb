class PackingLaneArticleStock < ApplicationRecord
  belongs_to :packing_lane
  belongs_to :article
  belongs_to :box

  validates :quantity, numericality: { greater_than_or_equal_to: 0 }
end
