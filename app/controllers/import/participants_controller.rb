module Import
  class ParticipantsController < ApplicationController
    authorize_resource

    include ::CsvImportable
  end
end
