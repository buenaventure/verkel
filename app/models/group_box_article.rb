class GroupBoxArticle < ApplicationRecord
  belongs_to :group
  belongs_to :box
  belongs_to :article

  scope :non_zero, -> { where.not(quantity: 0) }

  def quantity_unit
    article.quantity_unit * quantity
  end

  def article_quantity
    ArticleQuantity.new(article, quantity)
  end

  def humanize_quantity
    article_quantity.humanize
  end

  def warm?
    !article.needs_cooling? && !article.on_demand?
  end

  def cold?
    article.needs_cooling? && !article.on_demand?
  end

  def warm_on_demand?
    !article.needs_cooling? && article.on_demand?
  end

  def cold_on_demand?
    article.needs_cooling? && article.on_demand?
  end
end
