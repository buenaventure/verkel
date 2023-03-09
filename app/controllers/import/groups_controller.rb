module Import
  class GroupsController < ApplicationController
    authorize_resource

    include ::CsvImportable
  end
end
