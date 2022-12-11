class IngredientAlternativesController < ApplicationController
  authorize_resource
  before_action :set_ingredient, only: %i[new create]
  before_action :set_ingredient_alternative, only: %i[edit update destroy]

  def new
    @ingredient_alternative = @ingredient.ingredient_alternatives.new
  end

  def edit; end

  def create
    @ingredient_alternative = @ingredient.ingredient_alternatives.new(ingredient_alternative_params)

    respond_to do |format|
      if @ingredient_alternative.save
        format.html { redirect_to @ingredient, notice: 'Alternative Zutat wurde erfolgreich erstellt.' }
      else
        format.html { render :new, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @ingredient_alternative.update(ingredient_alternative_params)
        format.html { redirect_to @ingredient_alternative.ingredient, notice: 'Alternative Zutat wurde erfolgreich aktualisiert.' }
      else
        format.html { render :edit, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    respond_to do |format|
      if @ingredient_alternative.destroy
        format.html { redirect_to @ingredient_alternative.ingredient, notice: 'Alternative Zutat wurde erfolgreich gelöscht.', status: :see_other }
      else
        format.html do
          redirect_to @ingredient_alternative.ingredient, status: :see_other, alert: @ingredient_alternative.errors.full_messages
        end
      end
    end
  end

  private

  def breadcrumb_parent
    @ingredient
  end

  def set_ingredient
    @ingredient = Ingredient.find(params[:ingredient_id])
  end

  def set_ingredient_alternative
    @ingredient_alternative = IngredientAlternative.find(params[:id])
  end

  def ingredient_alternative_params
    params.require(:ingredient_alternative).permit(:alternative_id, :priority)
  end
end
