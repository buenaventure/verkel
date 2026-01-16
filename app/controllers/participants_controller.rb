class ParticipantsController < ApplicationController
  authorize_resource
  before_action :set_participant, only: %i[show edit update destroy]

  def index
    @participants = Participant.includes(:diets, :group).order(:id).all
    @meal_count = GroupMealParticipant.group(:participant_id).count
  end

  def show; end

  def new
    @participant = Participant.new
  end

  def edit; end

  def create
    @participant = Participant.new(participant_params)

    respond_to do |format|
      if @participant.save
        format.html { redirect_to @participant, notice: 'Teilnehmer*in wurde erfolgreich erstellt.' }
      else
        format.html { render :new, status: :unprocessable_content }
      end
    end
  end

  def update
    respond_to do |format|
      if @participant.update(participant_params)
        format.html { redirect_to @participant, notice: 'Teilnehmer*in wurde erfolgreich aktualisiert.' }
      else
        format.html { render :edit, status: :unprocessable_content }
      end
    end
  end

  def destroy
    respond_to do |format|
      if @participant.destroy
        format.html do
          redirect_to participants_url, notice: 'Teilnehmer*in wurde erfolgreich gelöscht.', status: :see_other
        end
      else
        format.html do
          redirect_to @participant, status: :see_other, alert: @participant.errors.full_messages
        end
      end
    end
  end

  private

  def set_participant
    @participant = Participant.find(params[:id])
  end

  def participant_params
    params.expect(participant: [:group_id, :age, :comment, :external_id, { diet_ids: [] }])
  end
end
