class GroupBoxIngredientsController < ApplicationController
  authorize_resource :group_box_ingredient, class: false
  def show
    @group = Group.find(params[:group_id])
    @box = Box.find(params[:box_id])
    @ingredient = Ingredient.find(params[:id])
    @calculations = GroupMealParticipantRecipeIngredientCalculation
                    .includes(:participant, meal: :recipe)
                    .joins('join meal_ingredient_boxes using(meal_id, ingredient_id)')
                    .where(
                      group: @group,
                      'meal_ingredient_boxes.box_id': @box.id,
                      ingredient: @ingredient
                    )
    @breadcrumbs = GroupBox.find_by(group: @group, box: @box).breadcrumb + [['Details']]
  end
end
