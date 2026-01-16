class GroupMealParticipationsController < ApplicationController
  authorize_resource
  before_action :set_group, only: %i[index new create]
  before_action :set_group_meal_participations, only: %i[edit update destroy]

  def index
    @group_meal_participations = @group.group_meal_participations.joins(meal: :recipe).order(
      'meals.datetime', 'meals.name', 'recipes.name', :participant_id
    ).includes(:participant, meal: :recipe)
  end

  def new
    @group_meal_participation = @group.group_meal_participations.new
  end

  def edit; end

  def create
    @group_meal_participation = @group.group_meal_participations.new(group_meal_participation_params)

    respond_to do |format|
      if @group_meal_participation.save
        format.html do
          redirect_to [@group, :group_meal_participations],
                      notice: 'Mahlzeiten-Teilnahme wurde erfolgreich erstellt.'
        end
      else
        format.html { render :new, status: :unprocessable_content }
      end
    end
  end

  def update
    respond_to do |format|
      if @group_meal_participation.update(group_meal_participation_params)
        format.html do
          redirect_to [@group, :group_meal_participations],
                      notice: 'Mahlzeiten-Teilnahme wurde erfolgreich aktualisiert.'
        end
      else
        format.html { render :edit, status: :unprocessable_content }
      end
    end
  end

  def destroy
    @group = @group_meal_participation.group
    respond_to do |format|
      if @group_meal_participation.destroy
        format.html do
          redirect_to [@group, :group_meal_participations], notice: 'Mahlzeiten-Teilnahme wurde erfolgreich gelöscht.',
                                                            status: :see_other
        end
      else
        format.html do
          redirect_to [@group, :group_meal_participations], status: :see_other,
                                                            alert: @group_meal_participation.errors.full_messages
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

  def set_group_meal_participations
    @group_meal_participation = GroupMealParticipation.find(params[:id])
  end

  def group_meal_participation_params
    params.expect(group_meal_participation: %i[meal_id participant_id])
  end
end
