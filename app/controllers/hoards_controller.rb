class HoardsController < ApplicationController
  authorize_resource
  before_action :set_article, only: %i[new create]
  before_action :set_hoard, only: %i[show edit update destroy]

  def new
    @hoard = @article.hoards.new
  end

  def edit; end

  def create
    @hoard = @article.hoards.new(hoard_params)

    respond_to do |format|
      if @hoard.save
        format.html { redirect_to @article, notice: 'Vorrat wurde erfolgreich erstellt.' }
      else
        format.html { render :new, status: :unprocessable_content }
      end
    end
  end

  def update
    respond_to do |format|
      if @hoard.update(hoard_params)
        format.html { redirect_to @hoard.article, notice: 'Vorrat wurde erfolgreich aktualisiert.' }
      else
        format.html { render :edit, status: :unprocessable_content }
      end
    end
  end

  def destroy
    @hoard.destroy

    respond_to do |format|
      format.html { redirect_to @hoard.article, notice: 'Vorrat wurde erfolgreich gelöscht.' }
    end
  end

  private

  def breadcrumb_parent
    @article
  end

  def set_article
    @article = Article.find(params[:article_id])
  end

  def set_hoard
    @hoard = Hoard.find(params[:id])
  end

  def hoard_params
    params.expect(hoard: %i[quantity until])
  end
end
