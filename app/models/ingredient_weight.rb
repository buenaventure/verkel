class IngredientWeight < ApplicationRecord
  belongs_to :ingredient
  validates :unit, presence: true, exclusion: { in: ['g'], message: '%<value> ist nicht sinnvoll.' }
  validates :weight, presence: true, numericality: { greater_than: 0 }

  def quantity_unit_base
    QuantityUnit.new(1, unit)
  end

  def quantity_unit_weight
    QuantityUnit.new(weight, 'g')
  end
end
