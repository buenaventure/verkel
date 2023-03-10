module Import
  class DietsIngredientsController < ApplicationController
    authorize_resource class: Ingredient

    include ::CsvImportable
  end
end
