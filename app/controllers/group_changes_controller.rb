class GroupChangesController < ApplicationController
  authorize_resource
  before_action :set_participant, only: %i[new create]
  before_action :set_group_change, only: %i[edit update destroy]

  def new
    @group_change = @participant.group_changes.new
  end

  def edit; end

  def create
    @group_change = @participant.group_changes.new(group_change_params)

    respond_to do |format|
      if @group_change.save
        format.html do
          redirect_to @participant, notice: 'Gruppenänderung wurde erfolgreich erstellt.'
        end
      else
        format.html { render :new, status: :unprocessable_content }
      end
    end
  end

  def update
    respond_to do |format|
      if @group_change.update(group_change_params)
        format.html do
          redirect_to @group_change.participant, notice: 'Gruppenänderung wurde erfolgreich geändert.'
        end
      else
        format.html { render :edit, status: :unprocessable_content }
      end
    end
  end

  def destroy
    @group_change.destroy

    respond_to do |format|
      format.html { redirect_to @group_change.participant, notice: 'Gruppenänderung wurde erfolgreich gelöscht.' }
    end
  end

  private

  def breadcrumb_parent
    @participant
  end

  def set_participant
    @participant = Participant.find(params[:participant_id])
  end

  def set_group_change
    @group_change = GroupChange.find(params[:id])
  end

  def group_change_params
    params.expect(group_change: %i[group_id timeframe_begin timeframe_end])
  end
end
