class GroupBoxIngredientUnitCache < ApplicationRecord
  include Calculatable

  belongs_to :group
  belongs_to :box
  belongs_to :ingredient

  MODEL_DEPENDENCIES = [
    Box, Diet, ExtraIngredient, Group, GroupMealParticipation, HungerFactor, Ingredient, IngredientAlternative,
    IngredientWeight, Meal, MealSelection, Participant, Recipe, RecipeIngredient, GroupChange
  ].freeze

  def self.do_calculate
    result = Scenic.database.refresh_materialized_view(table_name, concurrently: false, cascade: false)
    result.error_message.blank?
  end

  def quantity_unit
    QuantityUnit.new(quantity, unit)
  end

  def ingredient_unit
    IngredientUnit.new(ingredient_id, unit)
  end
end
