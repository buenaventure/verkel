class UpdateGroupMealParticipantRecipeIngredientSubstCalculationsToVersion2 < ActiveRecord::Migration[7.0]
  def change
    replace_view :group_meal_participant_recipe_ingredient_subst_calculations, version: 2, revert_to_version: 1
  end
end
