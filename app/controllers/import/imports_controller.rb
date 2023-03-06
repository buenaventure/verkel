module Import
  class ImportsController < ApplicationController
    authorize_resource :import, class: false
    before_action :set_breadcrumbs

    def show; end

    private

    def set_breadcrumbs
      @breadcrumbs = []
    end
  end
end
