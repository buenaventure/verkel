class Calculation < ApplicationRecord
  class << self
    def calculatables
      @calculatables ||= calculatable_models.each do |model|
        find_or_create_by(id: model.calculatable_name)
      end
    end

    def find_calculatable(calculatable_name)
      calculatables.find { _1.calculatable_name == calculatable_name } or raise ActiveRecord::RecordNotFound
    end

    private

    def calculatable_models
      load_models
      Object.descendants.select do
        _1.included_modules.include?(Calculatable)
      end
    end

    def load_models
      Rails.application.eager_load!
    rescue NameError
      nil
    end
  end
end
