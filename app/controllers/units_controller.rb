class UnitsController < ApplicationController
  load_and_authorize_resource

  def index; end

  def new; end

  def create
    respond_to do |format|
      if @unit.save
        format.html { redirect_to units_path, notice: 'Einheit wurde erfolgreich erstellt.' }
      else
        format.html { render :new, status: :unprocessable_content }
      end
    end
  end

  def destroy
    respond_to do |format|
      if @unit.destroy
        format.html { redirect_to units_url, notice: 'Einheit wurde erfolgreich gelöscht.', status: :see_other }
      else
        format.html do
          redirect_to units_path, status: :see_other, alert: @unit.errors.full_messages
        end
      end
    end
  end

  private

  def unit_params
    params.expect(unit: [:name])
  end
end
