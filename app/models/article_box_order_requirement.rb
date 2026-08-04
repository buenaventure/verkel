class ArticleBoxOrderRequirement < ApplicationRecord
  belongs_to :article
  belongs_to :box

  def quantity_unit
    article.quantity_unit * quantity
  end

  def stock_quantity_unit
    article.quantity_unit * stock
  end

  def ordered_quantity_unit
    article.quantity_unit * ordered
  end

  def article_quantity
    ArticleQuantity.new(article, quantity)
  end

  delegate :missing_price?, :line_total, to: :article_quantity
end
