module Import
  class ExtraIngredientsController < ApplicationController
    authorize_resource

    include ::CsvImportable

    def import_params
      params.require(:import).permit(:group_id, :box_id)
    end
  end
end
