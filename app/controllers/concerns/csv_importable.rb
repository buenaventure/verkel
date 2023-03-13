module CsvImportable
  extend ActiveSupport::Concern

  included do
    def create
      @breadcrumbs = []
      importer = importer_class.new(file: csv_file)
      importer.run!
      @report = importer.report
      render 'import/imports/create'
    end
  end

  private

  def importer_class
    "#{controller_name.classify.pluralize}Importer".constantize
  end

  def csv_file
    file_params[:file].tempfile.tap do |f|
      f.set_encoding(file_params.fetch(:encoding, 'UTF-8'))
    end
  end

  def file_params
    params.require(controller_name.to_sym)
  end
end
