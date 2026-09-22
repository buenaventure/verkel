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
    ordered_article_quantity.line_total
  end

  def price_delivered
    delivered_article_quantity.line_total
  end

  def quantity_unit_delivered
    article.quantity_unit * quantity_delivered
  end

  # Quantity on its way that is not yet part of article.stock.
  def quantity_incoming
    case order.state
    when 'ordered' then quantity_ordered
    when 'delivered' then quantity_delivered
    else 0
    end
  end

  def ordered_article_quantity
    ArticleQuantity.new(article, quantity_ordered)
  end

  def delivered_article_quantity
    ArticleQuantity.new(article, quantity_delivered)
  end
end
