class IngredientsController < ApplicationController
  authorize_resource
  before_action :set_ingredient, only: %i[show edit update destroy]

  def index
    @ingredients = \
      Ingredient.where(no_buy: false).order(commodity_group: :asc, name: :asc)
    load_ingredient_sums
  end

  def all
    @ingredients = Ingredient.all.order(commodity_group: :asc, name: :asc)
    load_ingredient_sums
    render :index
  end

  def with_missing_alternatives
    @ingredients = GroupMealParticipantRecipeIngredientSubstCalculation \
                   .where(final_ingredient_id: nil) \
                   .includes(:group, recipe_ingredient: :ingredient, participant: :diets, meal: :recipe) \
                   .group_by(&:ingredient)
  end

  def show; end

  def new
    @ingredient = Ingredient.new
  end

  def edit; end

  def create
    @ingredient = Ingredient.new(ingredient_params)

    respond_to do |format|
      if @ingredient.save
        format.html { redirect_to @ingredient, notice: 'Zutat wurde erfolgreich erstellt.' }
      else
        format.html { render :new, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @ingredient.update(ingredient_params)
        format.html { redirect_to @ingredient, notice: 'Zutat wurde erfolgreich aktualisiert.' }
      else
        format.html { render :edit, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    respond_to do |format|
      if @ingredient.destroy
        format.html { redirect_to ingredients_url, notice: 'Zutat wurde erfolgreich gelöscht.', status: :see_other }
      else
        format.html do
          redirect_to @ingredient, status: :see_other, alert: @ingredient.errors.full_messages
        end
      end
    end
  end

  private

  def set_ingredient
    @ingredient = Ingredient.find(params[:id])
  end

  def ingredient_params
    params.require(:ingredient).permit(:name, :commodity_group, :box_type, :uses_hunger_factor, diet_ids: [])
  end

  def load_ingredient_sums
    @unit_sums = \
      GroupBoxIngredientUnitCache \
      .group(:ingredient_id, :unit).sum(:quantity)\
      .group_by { |k, _v| k[0] } \
      .transform_values { |a| a.map { |b| QuantityUnit.new(b[1], b[0][1]) } }
    @missing_sums = \
      MissingIngredient \
      .group(:ingredient_id, :unit).sum(:quantity)\
      .group_by { |k, _v| k[0] } \
      .transform_values { |a| a.map { |b| QuantityUnit.new(b[1], b[0][1]) } }
  end
end
