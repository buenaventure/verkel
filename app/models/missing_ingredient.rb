class MissingIngredient < ApplicationRecord
  belongs_to :group
  belongs_to :box
  belongs_to :ingredient

  def quantity_unit
    QuantityUnit.new(quantity, unit)
  end
end
