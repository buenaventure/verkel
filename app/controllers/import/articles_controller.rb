module Import
  class ArticlesController < ApplicationController
    authorize_resource

    include ::CsvImportable
  end
end
