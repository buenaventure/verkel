class OrderArticlesController < ApplicationController
  authorize_resource
  before_action :set_order, only: %i[create]
  before_action :set_order_article, only: %i[destroy]

  def create
    @order_article = @order.order_articles.new(order_article_params)

    respond_to do |format|
      if @order_article.save
        format.html { redirect_to @order }
        format.turbo_stream
      else
        format.html { render partial: 'new', locals: { order_article: @order_article }, status: :unprocessable_content }
      end
    end
  end

  def destroy
    respond_to do |format|
      if @order_article.order.ordered?
        @order_article.destroy!
        format.turbo_stream { render turbo_stream: turbo_stream.remove(@order_article) }
        format.html { redirect_to @order_article.order, status: :see_other }
      else
        format.html do
          redirect_to @order_article.order, status: :see_other, alert: 'Kann nur im bestellten Zustand gelöscht werden'
        end
      end
    end
  end

  private

  def set_order
    @order = Order.find(params[:order_id])
  end

  def set_order_article
    @order_article = OrderArticle.find(params[:id])
  end

  def order_article_params
    params.expect(order_article: %i[article_id quantity_ordered quantity_delivered])
  end
end
