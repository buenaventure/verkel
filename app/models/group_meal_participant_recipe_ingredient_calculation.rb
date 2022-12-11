class GroupMealParticipantRecipeIngredientCalculation < ApplicationRecord
  belongs_to :group
  belongs_to :meal
  belongs_to :participant
  belongs_to :ingredient # this is the substituted ingredient

  def quantity_unit
    QuantityUnit.new(hunger_quantity, unit)
  end
end
