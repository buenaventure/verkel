class SuppliersController < ApplicationController
  authorize_resource
  before_action :set_supplier, only: %i[show edit update destroy]

  def index
    @suppliers = Supplier.with_next_order_data.order(:name)
  end

  def show; end

  def new
    @supplier = Supplier.new
  end

  def edit; end

  def create
    @supplier = Supplier.new(supplier_params)

    respond_to do |format|
      if @supplier.save
        format.html { redirect_to @supplier, notice: 'Lieferant wurde erfolgreich erstellt.' }
      else
        format.html { render :new, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @supplier.update(supplier_params)
        format.html { redirect_to @supplier, notice: 'Lieferant wurde erfolgreich aktualisiert.' }
      else
        format.html { render :edit, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    respond_to do |format|
      if @supplier.destroy
        format.html { redirect_to suppliers_url, notice: 'Lieferant wurde erfolgreich gelöscht.', status: :see_other }
      else
        format.html do
          redirect_to @supplier, status: :see_other, alert: @supplier.errors.full_messages
        end
      end
    end
  end

  private

  def set_supplier
    @supplier = Supplier.find(params[:id])
  end

  def supplier_params
    params.require(:supplier).permit(:name, :notes, :delivery_time, :address)
  end
end
