module CsvImportable
  extend ActiveSupport::Concern

  included do
    def create
      if file_params[:file]
        @breadcrumbs = []
        model_default_params = import_params
        importer = importer_class.new(file: csv_file) do
          model_defaults model_default_params
        end
        importer.run!
        @report = importer.report
        render 'import/imports/create'
      else
        redirect_back fallback_location: root_path, status: :see_other,
                      alert: 'Datei wird benötigt'
      end
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

  def import_params
    {}
  end
end
