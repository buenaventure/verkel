module Calculatable
  extend ActiveSupport::Concern

  MODEL_DEPENDENCIES = [].freeze
  CALCULATION_DEPENDENCIES = [].freeze

  class_methods do
    def calculate
      Calculation.transaction do
        return false unless calculation.update(
          updated_at: Time.zone.now,
          count: model_dependencies_state['count']
        )

        do_calculate
      end
    end

    def fresh?
      state = model_dependencies_state
      return true if state.nil?

      calculation_dependencies_fresh_and_unchanged &&
        (state['updated_at'].nil? || calculation.updated_at > state['updated_at']) &&
        calculation.count == state['count']
    end

    def calculatable_name
      name
    end

    def calculatable_name_humanized
      I18n.t "calculatable.#{calculatable_name}"
    end

    def calculation
      Calculation.find(calculatable_name)
    end

    private

    def calculation_dependencies_fresh_and_unchanged
      self::CALCULATION_DEPENDENCIES.all? do |calculatable|
        calculatable.fresh? && calculatable.calculation.updated_at < calculation.updated_at
      end
    end

    def model_dependencies_state
      subquery_sql =
        self::MODEL_DEPENDENCIES.map do
          _1.select('max(updated_at) over (), count(*) over ()').to_sql
        end.join(') UNION (')
      ActiveRecord::Base.connection.execute(
        "SELECT max(max) as updated_at, sum(count) as count FROM ((#{subquery_sql})) as _"
      )[0]
    end
  end
end
