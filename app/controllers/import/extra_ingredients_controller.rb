module Import
  class ExtraIngredientsController < ApplicationController
    authorize_resource

    include ::CsvImportable

    def import_params
      params.expect(import: %i[group_id box_id])
    end
  end
end
