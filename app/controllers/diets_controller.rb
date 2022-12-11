class DietsController < ApplicationController
  authorize_resource
  before_action :set_diet, only: %i[show edit update destroy]

  def index
    @diets = Diet.order(:category, :name)
  end

  def show; end

  def new
    @diet = Diet.new
  end

  def edit; end

  def create
    @diet = Diet.new(diet_params)

    respond_to do |format|
      if @diet.save
        format.html { redirect_to @diet, notice: 'Ernährungsweise wurde erfolgreich erstellt.' }
      else
        format.html { render :new, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @diet.update(diet_params)
        format.html { redirect_to @diet, notice: 'Ernährungsweise wurde erfolgreich aktualisiert.' }
      else
        format.html { render :edit, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    respond_to do |format|
      if @diet.destroy
        format.html { redirect_to diets_url, notice: 'Ernährungsweise wurde erfolgreich gelöscht.', status: :see_other }
      else
        format.html do
          redirect_to @diet, status: :see_other, alert: @diet.errors.full_messages
        end
      end
    end
  end

  private

  def set_diet
    @diet = Diet.find(params[:id])
  end

  def diet_params
    params.require(:diet).permit(:name, :category, ingredient_ids: [])
  end
end
