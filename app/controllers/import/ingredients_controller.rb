module Import
  class IngredientsController < ApplicationController
    authorize_resource

    def create
      importer = IngredientsImporter.new(
        file: ingredients_params[:file].tempfile.set_encoding('utf-8')
      )
      importer.run!
      @report = importer.report
      render 'import/imports/create'
    end

    private

    def ingredients_params
      params.require(:ingredients).permit(:file)
    end
  end
end
