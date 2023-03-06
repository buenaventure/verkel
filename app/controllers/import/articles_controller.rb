module Import
  class ArticlesController < ApplicationController
    authorize_resource

    def create
      importer = ArticlesImporter.new(
        file: articles_params[:file].tempfile.set_encoding('utf-8')
      )
      importer.run!
      @report = importer.report
      render 'import/imports/create'
    end

    private

    def articles_params
      params.require(:articles).permit(:file)
    end
  end
end
