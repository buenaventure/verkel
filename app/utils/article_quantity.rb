# frozen_string_literal: true

ArticleQuantity = Struct.new(:article, :quantity) do
  include ActionView::Helpers::NumberHelper

  def quantity_unit
    article.quantity_unit * quantity
  end

  def humanize
    case article.packing_type
    when 'bulk' then quantity_unit.humanize
    when 'piece' then number_with_delimiter(quantity)
    else raise ArgumentError
    end
  end

  def missing_price?
    article&.price.nil?
  end

  def line_total
    return nil if missing_price?

    (quantity * article.price).round(2)
  end
end
