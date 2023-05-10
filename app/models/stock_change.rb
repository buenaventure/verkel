class StockChange < ApplicationRecord
  belongs_to :article
  belongs_to :user

  def quantity_unit
    article.quantity_unit * quantity
  end

  def quantity_unit_result
    article.quantity_unit * result
  end

  def reference_object
    @reference_object ||= GlobalID::Locator.locate reference
  rescue StandardError
    reference
  end
end
