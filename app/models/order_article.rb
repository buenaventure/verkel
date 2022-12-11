class OrderArticle < ApplicationRecord
  belongs_to :order
  belongs_to :article

  validates :article, uniqueness: { scope: :order }
  validates :quantity_ordered, numericality: { greater_than_or_equal_to: 0 }
  validates :quantity_delivered, numericality: { greater_than_or_equal_to: 0 }

  scope :non_zero, -> { where.not(quantity_ordered: 0, quantity_delivered: 0) }

  def quantity_unit_ordered
    article.quantity_unit * quantity_ordered
  end

  def price_ordered
    return nil if article&.price.nil?

    (quantity_ordered * article.price).round(2)
  end

  def quantity_unit_delivered
    article.quantity_unit * quantity_delivered
  end
end
