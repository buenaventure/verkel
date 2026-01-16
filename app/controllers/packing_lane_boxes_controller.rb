class PackingLaneBoxesController < ApplicationController
  authorize_resource
  before_action :set_packing_lane_box,
                only: %i[show edit create_stock update move_diff_from_stock move_to_stock packing_list]

  def show
    @packing_lane_article_stock = @packing_lane_box.packing_lane_article_stocks.new
  end

  def edit; end

  def create_stock
    @packing_lane_article_stock = @packing_lane_box.packing_lane_article_stocks.new(packing_lane_article_stock_params)

    respond_to do |format|
      if @packing_lane_article_stock.save
        format.html { redirect_to @packing_lane_box }
      else
        format.html { render :show, status: :unprocessable_content }
      end
    end
  end

  def update
    respond_to do |format|
      if @packing_lane_box.update(packing_lane_box_params)
        format.html do
          redirect_to packing_lane_box_url(@packing_lane_box), notice: 'Packstraße wurde erfolgreich bearbeitet.'
        end
      else
        format.html do
          render :edit, status: :unprocessable_content
        end
      end
    end
  end

  def move_diff_from_stock
    respond_to do |format|
      @packing_lane_box.move_diff_from_stock current_user
      format.html do
        redirect_to @packing_lane_box,
                    notice: 'Fehlbestand wurde aus dem Lager in die Packstraße gebucht.',
                    status: :see_other
      end
    end
  end

  def move_to_stock
    respond_to do |format|
      @packing_lane_box.move_to_stock current_user
      format.html do
        redirect_to @packing_lane_box, notice: 'Bestand wurde zurück ins Lager gebucht.', status: :see_other
      end
    end
  end

  def packing_list
    respond_to do |format|
      format.pdf do
        pdf = PackingListLane.new(@packing_lane_box, filter: filter_param)
        send_data pdf.render,
                  filename: pdf.filename,
                  type: 'application/pdf',
                  disposition: 'inline'
      end
    end
  end

  private

  def filter_param
    case params['filter']
    when 'warm' then :warm
    when 'cold' then :cold
    end
  end

  def breadcrumb_parent
    @packing_lane_box.packing_lane
  end

  def set_packing_lane_box
    @packing_lane_box = PackingLaneBox.find(params[:id])
  end

  def packing_lane_box_params
    params.expect(packing_lane_box: [packing_lane_article_stocks_attributes: %i[id quantity]])
  end

  def packing_lane_article_stock_params
    params.expect(packing_lane_article_stock: %i[article_id quantity])
  end
end
