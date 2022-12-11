class GroupMealParticipantRecipeIngredientSubstCalculation < ApplicationRecord
  belongs_to :group
  belongs_to :meal
  belongs_to :participant
  belongs_to :recipe_ingredient

  delegate :ingredient, to: :recipe_ingredient

  def diet_string
    participant.diets.map(&:name).sort.join(', ')
  end
end
