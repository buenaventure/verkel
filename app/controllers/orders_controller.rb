class OrdersController < ApplicationController
  load_and_authorize_resource
  # before_action :set_order, only: %i[show edit edit_quantities update destroy order deliver store cancel]
  before_action :set_order_articles, only: %i[show edit_quantities]

  def index
    @orders = Order.joins(:supplier).includes(:supplier).order('suppliers.name', :coverage)
  end

  def show
    respond_to do |format|
      format.html do
        @order_article = @order.order_articles.new
      end
      format.pdf do
        pdf = OrderDocument.new(@order)
        send_data pdf.render,
                  filename: pdf.filename,
                  type: 'application/pdf',
                  disposition: 'inline'
      end
    end
  end

  def new
    @order = Order.new(params.permit(:supplier_id))
  end

  def edit; end

  def edit_quantities; end

  def create
    @order = Order.new(order_params)

    respond_to do |format|
      if @order.save
        format.html { redirect_to @order, notice: 'Bestellung wurde erfolgreich erstellt.' }
      else
        format.html { render :new, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @order.update(order_params)
        format.html { redirect_to @order }
      else
        format.html do
          if order_params.include?('order_articles_attributes')
            render :edit_quantities, status: :unprocessable_entity
          else
            render :edit, status: :unprocessable_entity
          end
        end
      end
    end
  end

  def destroy
    respond_to do |format|
      if @order.destroy
        format.html { redirect_to orders_url, notice: 'Bestellung wurde erfolgreich gelöscht.', status: :see_other }
      else
        format.html do
          redirect_to @order, status: :see_other, alert: @order.errors.full_messages
        end
      end
    end
  end

  def order
    respond_to do |format|
      if @order.order
        format.html { redirect_to @order, notice: 'Bestellung wurde erfolgreich als bestellt eingetragen.' }
      else
        format.html { redirect_to @order, alert: 'Bestellung konnte nicht als bestellt eingetragen werden.' }
      end
    end
  end

  def deliver
    respond_to do |format|
      if @order.deliver
        format.html { redirect_to @order, notice: 'Bestellung wurde erfolgreich als geliefert eingetragen.' }
      else
        format.html { redirect_to @order, alert: 'Bestellung konnte nicht als geliefert eingetragen werden.' }
      end
    end
  end

  def store
    respond_to do |format|
      if @order.store
        format.html { redirect_to @order, notice: 'Bestellung wurde erfolgreich als eingelagert eingetragen.' }
      else
        format.html { redirect_to @order, alert: 'Bestellung konnte nicht als eingelagert eingetragen werden.' }
      end
    end
  end

  def cancel
    respond_to do |format|
      if @order.cancel
        format.html { redirect_to @order, notice: 'Bestellung wurde erfolgreich als abgebrochen eingetragen.' }
      else
        format.html { redirect_to @order, alert: 'Bestellung konnte nicht als abgebrochen eingetragen werden.' }
      end
    end
  end

  private

  def set_order
    @order = Order.find(params[:id])
  end

  def set_order_articles
    @order_articles = @order.order_articles\
                            .includes(article: :ingredient) \
                            .joins(article: :ingredient).order(:'ingredients.name', :'articles.name')
  end

  def order_params
    return params.require(:order).permit(order_articles_attributes: %i[id quantity_delivered]) if current_user.laga?

    params.require(:order).permit(
      :supplier_id, :coverage_begin, :coverage_end,
      order_articles_attributes: %i[id quantity_ordered quantity_delivered]
    )
  end
end
