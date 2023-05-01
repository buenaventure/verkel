class ExtraIngredientsController < ApplicationController
  authorize_resource
  before_action :set_group_box, only: %i[new create]
  before_action :set_extra_ingredient, only: %i[edit update destroy]

  def new
    @extra_ingredient = @group_box.extra_ingredients.new
  end

  def edit; end

  def create
    @extra_ingredient = @group_box.extra_ingredients.new(extra_ingredient_params)

    respond_to do |format|
      if @extra_ingredient.save
        format.html do
          redirect_to [@group_box.box, @group_box.group], notice: 'Extra-Zutat wurde erfolgreich erstellt.'
        end
      else
        format.html { render :new, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @extra_ingredient.update(extra_ingredient_params)
        format.html do
          redirect_to [@extra_ingredient.box, @extra_ingredient.group],
                      notice: 'Extra-Zutat wurde erfolgreich aktualisiert.'
        end
      else
        format.html { render :edit, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    respond_to do |format|
      if @extra_ingredient.destroy
        format.html do
          redirect_to [@extra_ingredient.box, @extra_ingredient.group], notice: 'Extra-Zutat wurde erfolgreich gelöscht.',
                                                                        status: :see_other
        end
      else
        format.html do
          redirect_to [@extra_ingredient.box, @extra_ingredient.group], status: :see_other,
                                                                        alert: @extra_ingredient.errors.full_messages
        end
      end
    end
  end

  private

  def breadcrumb_parent
    @group_box
  end

  def set_group_box
    @group_box = GroupBox.find_by(group_id: params[:group_id], box_id: params[:box_id])
  end

  def set_extra_ingredient
    @extra_ingredient = ExtraIngredient.find(params[:id])
  end

  def extra_ingredient_params
    params.require(:extra_ingredient).permit(:ingredient_id, :quantity, :unit, :purpose)
  end
end
