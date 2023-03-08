module Import
  class IngredientsController < ApplicationController
    authorize_resource

    include ::CsvImportable
  end
end
