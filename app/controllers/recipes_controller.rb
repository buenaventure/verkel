class RecipesController < ApplicationController
  authorize_resource
  before_action :set_recipe, only: %i[show edit update destroy]

  def index
    @recipes = Recipe.includes(:meals).order(:name).all
  end

  def show; end

  def kochbuch
    @recipes = Recipe.with_meal.distinct
    respond_to do |format|
      format.pdf do
        pdf = Kochbuch.new(@recipes)
        send_data pdf.render,
                  filename: 'kochbuch.pdf',
                  type: 'application/pdf',
                  disposition: 'inline'
      end
    end
  end

  def new
    @recipe = Recipe.new
  end

  def edit; end

  def create
    @recipe = Recipe.new(recipe_params)

    respond_to do |format|
      if @recipe.save
        format.html { redirect_to @recipe, notice: 'Repept wurde erfolgreich erstellt.' }
      else
        format.html { render :new, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @recipe.update(recipe_params)
        format.html { redirect_to @recipe, notice: 'Repept wurde erfolgreich aktualisiert.' }
      else
        format.html { render :edit, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    respond_to do |format|
      if @recipe.destroy
        format.html { redirect_to recipes_url, notice: 'Rezept wurde erfolgreich gelöscht.', status: :see_other }
      else
        format.html do
          redirect_to @recipe, status: :see_other, alert: @recipe.errors.full_messages
        end
      end
    end
  end

  private

  def set_recipe
    @recipe = Recipe.find(params[:id])
  end

  def recipe_params
    params.require(:recipe).permit(:name, :servings, :content, :lama_uuid)
  end
end
