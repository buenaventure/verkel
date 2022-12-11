class ImportsController < ApplicationController
  authorize_resource :import, class: false
  before_action :set_breadcrumbs

  def show; end

  def lama
    @output = LamaImport.all
    render :show
  end

  private

  def set_breadcrumbs
    @breadcrumbs = []
  end
end
