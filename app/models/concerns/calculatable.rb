module Calculatable
  extend ActiveSupport::Concern

  class_methods do
    def calculate
      Calculation.transaction do
        return false unless calculation.update(**dependencies_state)

        do_calculate
      end
    end

    def fresh?
      state = dependencies_state
      return true if state.nil?

      calculation.updated_at == state['updated_at'] &&
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

    def dependencies_state
      subquery_sql =
        self::DEPENDENCIES.map do
          _1.select('max(updated_at) over (), count(*) over ()').to_sql
        end.join(') UNION (')
      ActiveRecord::Base.connection.execute(
        "SELECT max(max) as updated_at, sum(count) as count FROM ((#{subquery_sql})) as _"
      )[0]
    end
  end
end
