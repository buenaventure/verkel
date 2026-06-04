# frozen_string_literal: true

class GroupBoxArticleCost < ApplicationRecord
  include ActionView::Helpers::NumberHelper

  self.primary_key = :group_box_article_id

  belongs_to :group
  belongs_to :box
  belongs_to :article

  scope :final, -> { where(is_final: true) }
  scope :missing_price, -> { where(unit_price: nil) }

  def missing_price?
    unit_price.nil?
  end

  def humanize_quantity
    case article.packing_type
    when 'bulk' then (article.quantity_unit * quantity).humanize
    when 'piece' then number_with_delimiter(quantity)
    else raise ArgumentError
    end
  end
end
