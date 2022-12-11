class BoxesController < ApplicationController
  authorize_resource
  before_action \
    :set_box,
    only: %i[
      show edit update destroy
      packing_lists_articles
      packing_lists_groups
      packing_lists_missing_ingredients
      ingredient_meals
      packing_lists_lanes
      all_packing_lists
    ]

  def index
    @boxes = Box.all
  end

  def show; end

  def ingredient_meals
    @ingredient_meals = \
      MealIngredientBox
      .where(box: @box)
      .includes(meal: :recipe)
      .group_by(&:ingredient_id)
      .transform_values do |mibs|
        mibs.map(&:meal)
      end
  end

  def new
    @box = Box.new
  end

  def edit; end

  def create
    @box = Box.new(box_params)

    respond_to do |format|
      if @box.save
        format.html { redirect_to @box, notice: 'Kiste wurde erfolgreich erstellt.' }
      else
        format.html { render :new, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @box.update(box_params)
        format.html { redirect_to @box, notice: 'Kiste wurde erfolgreich aktualisiert.' }
      else
        format.html { render :edit, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    respond_to do |format|
      if @box.destroy
        format.html { redirect_to boxes_url, notice: 'Kiste wurde erfolgreich gelöscht.', status: :see_other }
      else
        format.html do
          redirect_to @box, status: :see_other, alert: @box.errors.full_messages
        end
      end
    end
  end

  def packing_lists_groups
    render_pdf PackingListsGroups.new(@box)
  end

  def packing_lists_articles
    render_pdf PackingListsArticles.new(@box, filter: filter_param)
  end

  def packing_lists_missing_ingredients
    render_pdf PackingListsMissingIngredients.new(@box)
  end

  def packing_lists_lanes
    render_pdf PackingListsLanes.new(@box)
  end

  def all_packing_lists
    render_pdf AllBoxLists.new(@box)
  end

  private

  def filter_param
    case params['filter']
    when 'warm' then :warm
    when 'cold' then :cold
    end
  end

  def set_box
    @box = Box.find(params[:id])
  end

  def box_params
    params.require(:box).permit(:datetime, :box_type, :status, :groups_info)
  end
end
