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
end
