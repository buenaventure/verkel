class StockChangesController < ApplicationController
  authorize_resource
  before_action :set_article, only: %i[index]

  def index
    @stock_changes = @article.stock_changes
  end

  private

  def breadcrumb_parent
    @article
  end

  def set_article
    @article = Article.find(params[:article_id])
  end
end
