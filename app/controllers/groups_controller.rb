class GroupsController < ApplicationController
  authorize_resource
  before_action :set_group, only: %i[show edit update destroy]

  def index
    @groups = Group.order(name: :asc).includes(:packing_lane).all
    @servings = \
      GroupMealParticipation
      .group(:group_id, :meal_id).count
      .group_by { |k, _v| k[0] }
      .transform_values { |vs| vs.map { |v| v[1] }.max }
  end

  def meals_overview
    @groups = Group.order(internal_name: :asc, name: :asc).all
    @meals = \
      Meal
      .includes(:recipe)
      .order(datetime: :asc)
    @servings = GroupMealParticipant.group(:group_id, :meal_id).count
    respond_to do |format|
      format.html
      format.csv
    end
  end

  def diets_overview
    @groups = Group.reorder(internal_name: :asc, name: :asc).all
    @diets = Diet.order(:name)
    @group_participants = \
      GroupMealParticipant \
      .distinct.pluck(:group_id, :participant_id) \
      .group_by { |i| i[0] }.transform_values { |v| v.map { |i| i[1] } }
  end

  def show
    @group_meals = @group \
                   .group_meals \
                   .includes(meal: %i[recipe box]) \
                   .joins(:meal) \
                   .order('meals.datetime': :asc)
    @servings = @group.group_meal_participants.group(:meal_id).count
  end

  def new
    @group = Group.new
  end

  def edit; end

  def create
    @group = Group.new(group_params)

    respond_to do |format|
      if @group.save
        format.html { redirect_to @group, notice: 'Kochgruppe wurde erfolgreich erstellt.' }
      else
        format.html { render :new, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @group.update(group_params)
        format.html { redirect_to @group, notice: 'Kochgruppe wurde erfolgreich aktualisiert.' }
      else
        format.html { render :edit, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    respond_to do |format|
      if @group.destroy
        format.html { redirect_to groups_url, notice: 'Kochgruppe wurde erfolgreich gelöscht.', status: :see_other }
      else
        format.html do
          redirect_to @group, status: :see_other, alert: @group.errors.full_messages
        end
      end
    end
  end

  private

  def set_group
    @group = Group.find(params[:id])
  end

  def group_params
    params.require(:group).permit(:name, :internal_name, :hunger_factor, :notes, :packing_lane_id)
  end
end
