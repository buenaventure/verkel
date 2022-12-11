class GroupBoxIngredientUnitCache < ApplicationRecord
  belongs_to :group
  belongs_to :box
  belongs_to :ingredient

  def quantity_unit
    QuantityUnit.new(quantity, unit)
  end

  def self.refresh
    Scenic.database.refresh_materialized_view(table_name, concurrently: false, cascade: false)
  end

  def ingredient_unit
    IngredientUnit.new(ingredient_id, unit)
  end
end
