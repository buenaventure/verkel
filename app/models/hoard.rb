class Hoard < ApplicationRecord
  belongs_to :article

  validates :quantity, numericality: { greater_than_or_equal_to: 0 }
  validates :missing_quantity, numericality: { greater_than_or_equal_to: 0 }

  def quantity_unit
    article.quantity_unit * quantity
  end
end
