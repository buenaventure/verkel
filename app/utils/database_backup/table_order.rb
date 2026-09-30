# frozen_string_literal: true

module DatabaseBackup
  # Orders tables so referenced tables come before the tables referencing them.
  class TableOrder
    def initialize(tables)
      @dependencies = tables.index_with { [] }
      foreign_keys.each do |table, referenced|
        @dependencies[table] << referenced if table != referenced && tables.include?(referenced)
      end
    end

    def to_a
      ordered = []
      remaining = @dependencies.dup
      until remaining.empty?
        ready = remaining.select { |_, deps| (deps - ordered).empty? }.keys
        raise Error, "Zyklische Abhängigkeit zwischen Tabellen: #{remaining.keys.join(', ')}" if ready.empty?

        ordered.concat(ready.sort)
        remaining.except!(*ready)
      end
      ordered
    end

    private

    def foreign_keys
      ActiveRecord::Base.connection.select_rows(<<~SQL.squish)
        SELECT child.relname, parent.relname
        FROM pg_constraint
        JOIN pg_class child ON child.oid = pg_constraint.conrelid
        JOIN pg_class parent ON parent.oid = pg_constraint.confrelid
        JOIN pg_namespace ON pg_namespace.oid = child.relnamespace
        WHERE pg_constraint.contype = 'f' AND pg_namespace.nspname = ANY(current_schemas(false))
      SQL
    end
  end
end
