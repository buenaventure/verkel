class MealSelectionsController < ApplicationController
  authorize_resource
  before_action :set_group, only: %i[index create]
  before_action :set_meal_selection, only: %i[destroy]

  def index
    Meal.optional.unselected_by(@group).map do |meal|
      @group.meal_selections.new(meal:)
    end
    @meal_selections = @group.meal_selections.sort_by(&:datetime)
  end

  def create
    @meal_selection = @group.meal_selections.new(meal_selection_params)

    respond_to do |format|
      if @meal_selection.save
        format.html do
          redirect_to [@group, :meal_selections],
                      notice: 'Mahlzeiten-Auswahl wurde erfolgreich erstellt.'
        end
      else
        format.html { render :new, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @group = @meal_selection.group
    respond_to do |format|
      if @meal_selection.destroy
        format.html do
          redirect_to [@group, :meal_selections], notice: 'Mahlzeiten-Auswahl wurde erfolgreich gelöscht.',
                                                  status: :see_other
        end
      else
        format.html do
          redirect_to [@group, :meal_selections], status: :see_other,
                                                  alert: @meal_selection.errors.full_messages
        end
      end
    end
  end

  private

  def breadcrumb_parent
    @group
  end

  def set_group
    @group = Group.find(params[:group_id])
  end

  def set_meal_selection
    @meal_selection = MealSelection.find(params.extract_value(:id))
  end

  def meal_selection_params
    params.require(:meal_selection).permit(:meal_id)
  end
end
