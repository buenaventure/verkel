class CalculationsController < ApplicationController
  authorize_resource

  before_action :set_calculatable, only: :update

  def update
    respond_to do |format|
      if @calculatable.calculate
        format.html do
          redirect_back fallback_location: root_path,
                        notice: "#{@calculatable.calculatable_name_humanized} wurde neu berechnet."
        end
      else
        format.html { redirect_back fallback_location: root_path, error: 'Fehler bei der Berechnung' }
      end
    end
  end

  private

  def set_calculatable
    @calculatable = Calculation.find_calculatable(params[:id])
  end
end
