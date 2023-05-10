class ArticlesController < ApplicationController
  authorize_resource
  before_action :set_article, only: %i[show edit update destroy update_stock]

  def index
    @articles = \
      Article \
      .includes(:supplier, :ingredient, :active_packing_lane_article_stocks, :article_box_order_requirements) \
      .joins(:ingredient).lexical
    @order_counts = OrderArticle.all.group(:article_id).count
  end

  def laga
    @articles = Article.includes(:supplier, :ingredient).joins(:ingredient).lexical
    @articles = filter(@articles)
  end

  def show; end

  def new
    @article = Article.new(params.permit(:supplier_id, :ingredient_id))
  end

  def edit; end

  def create
    @article = Article.new(article_params)

    respond_to do |format|
      if @article.save
        format.html { redirect_to @article, notice: 'Artikel wurde erfolgreich erstellt.' }
      else
        format.html { render :new, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @article.update(article_params)
        format.html { redirect_to @article, notice: 'Artikel wurde erfolgreich aktualisiert.' }
      else
        format.html { render :edit, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    respond_to do |format|
      if @article.destroy
        format.html { redirect_to articles_url, notice: 'Artikel wurde erfolgreich gelöscht.', status: :see_other }
      else
        format.html do
          redirect_to @article, status: :see_other, alert: @article.errors.full_messages
        end
      end
    end
  end

  def update_stock
    @article_stock_action = ArticleStockAction.new(
      article: @article,
      user: current_user,
      **params.require(:article_stock_action).permit(:action)
    )
    @article_stock_action.call if @article_stock_action.valid?
  end

  def inventory_list
    render_pdf InventoryList.new
  end

  private

  def set_article
    @article = Article.find(params[:id])
  end

  def article_params
    params.require(:article).permit(
      :ingredient_id, :supplier_id, :price, :quantity, :unit, :notes, :name,
      :stock, :order_limit, :priority, :needs_cooling, :packing_type, :nr
    )
  end

  def filter(articles)
    filter_search(filter_cooling(articles))
  end

  def filter_cooling(articles)
    return articles unless params[:cooling]

    case params[:cooling]
    when 'warm' then articles.where(needs_cooling: false)
    when 'cold' then articles.where(needs_cooling: true)
    else articles
    end
  end

  def filter_search(articles)
    return articles unless params[:search]

    articles.where(
      'articles.name ilike ? or ' \
      'ingredients.name ilike ? or ' \
      'suppliers.name ilike ?',
      "%#{params[:search]}%", "%#{params[:search]}%", "%#{params[:search]}%"
    )
  end
end
