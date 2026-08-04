# frozen_string_literal: true

# Cost calculation row for one article assigned to a group box.
class GroupBoxArticleCost < ApplicationRecord
  self.primary_key = :group_box_article_id

  belongs_to :group
  belongs_to :box
  belongs_to :article

  scope :final, -> { where(is_final: true) }
  scope :missing_price, -> { where(unit_price: nil) }

  def missing_price?
    unit_price.nil?
  end

  def article_quantity
    ArticleQuantity.new(article, quantity)
  end
end
