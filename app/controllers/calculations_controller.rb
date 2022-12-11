class CalculationsController < ApplicationController
  authorize_resource :calculation, class: false
  def demand
    result = GroupBoxIngredientUnitCache.refresh

    respond_to do |format|
      if result.error_message.blank?
        format.html { redirect_back fallback_location: root_path, notice: 'Bedarf wurde neu berechnet.' }
      else
        format.html { redirect_back fallback_location: root_path, error: "Fehler bei der Bedarfsberechnung: #{result.error_message}" }
      end
    end
  end

  def packing
    ArticlePackingPlanner.new.run

    respond_to do |format|
      format.html { redirect_back fallback_location: root_path, notice: 'Kistenpacken wurde neu geplant.' }
    end
  end
end
