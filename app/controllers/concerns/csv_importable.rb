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
    f = params.require(controller_name.to_sym)[:file].tempfile
    char_det = CharDet.detect(f.read)
    f.rewind
    f.set_encoding(char_det['encoding'])
    f
  end
end
