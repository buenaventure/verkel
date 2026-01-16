class PackingLanesController < ApplicationController
  authorize_resource
  before_action :set_packing_lane, only: %i[show edit update destroy]

  def index
    @packing_lanes = PackingLane.order(:name)
  end

  def show; end

  def new
    @packing_lane = PackingLane.new
  end

  def edit; end

  def create
    @packing_lane = PackingLane.new(packing_lane_params)

    respond_to do |format|
      if @packing_lane.save
        format.html { redirect_to packing_lane_url(@packing_lane), notice: 'Packstraße wurde erfolgreich erstellt.' }
      else
        format.html { render :new, status: :unprocessable_content }
      end
    end
  end

  def update
    respond_to do |format|
      if @packing_lane.update(packing_lane_params)
        format.html { redirect_to packing_lane_url(@packing_lane), notice: 'Packstraße wurde erfolgreich bearbeitet.' }
      else
        format.html do
          render :edit, status: :unprocessable_content
        end
      end
    end
  end

  def destroy
    respond_to do |format|
      if @packing_lane.destroy
        format.html do
          redirect_to packing_lanes_url, notice: 'Packstraße wurde erfolgreich gelöscht.', status: :see_other
        end
      else
        format.html { redirect_to @packing_lane, status: :see_other, alert: @packing_lane.errors.full_messages }
      end
    end
  end

  private

  def set_packing_lane
    @packing_lane = PackingLane.find(params[:id])
  end

  def packing_lane_params
    params.expect(packing_lane: [:name])
  end
end
