class Hoard < ApplicationRecord
  belongs_to :article

  validates :quantity, numericality: { greater_than_or_equal_to: 0 }
  validates :missing_quantity, numericality: { greater_than_or_equal_to: 0 }

  def quantity_unit
    article.quantity_unit * quantity
  end

  def article_quantity
    ArticleQuantity.new(article, missing_quantity)
  end

  delegate :missing_price?, :line_total, to: :article_quantity
end
