class MealsController < ApplicationController
  authorize_resource
  before_action :set_meal, only: %i[show edit update destroy]

  def index
    @meals = Meal \
             .includes(:recipe, :box, { group_meals: :group }) \
             .order(datetime: :asc)
    @servings = GroupMealParticipant.group(:meal_id).count
  end

  def show
    @servings = @meal.group_meal_participants.group(:group_id).count
  end

  def new
    @meal = Meal.new
  end

  def edit; end

  def create
    @meal = Meal.new(meal_params)

    respond_to do |format|
      if @meal.save
        format.html { redirect_to @meal, notice: 'Mahlzeit wurde erfolgreich erstellt.' }
      else
        format.html { render :new, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @meal.update(meal_params)
        format.html { redirect_to @meal, notice: 'Mahlzeit wurde erfolgreich aktualisiert.' }
      else
        format.html { render :edit, status: :unprocessable_entity }
      end
    end
  end

  def destroy
  respond_to do |format|
    if @meal.destroy
      format.html { redirect_to meals_url, notice: 'Mahlzeit wurde erfolgreich gelöscht.', status: :see_other }
    else
      format.html do
        redirect_to @meal, status: :see_other, alert: @meal.errors.full_messages
      end
    end
  end
end

  private

  def set_meal
    @meal = Meal.find(params[:id])
  end

  def meal_params
    params.require(:meal).permit(:datetime, :name, :recipe_id, :estimated_share, :optional, :bundle)
  end
end
