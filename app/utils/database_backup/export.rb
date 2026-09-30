# frozen_string_literal: true

module DatabaseBackup
  # Writes all data into a backup archive.
  class Export
    def run
      Archive.write do |add_file|
        consistent_snapshot do
          tables = DatabaseBackup.data_tables.sort.index_with { connection.columns(it).map(&:name) }
          add_file.call(MANIFEST_FILE, JSON.pretty_generate(manifest(tables)))
          tables.each_key { add_file.call("tables/#{it}.json", table_json(it)) }
          add_blob_files(add_file)
        end
      end
    end

    private

    def connection
      ActiveRecord::Base.connection
    end

    def consistent_snapshot(&)
      if connection.transaction_open?
        yield
      else
        connection.transaction(isolation: :repeatable_read, &)
      end
    end

    def manifest(tables)
      {
        format: FORMAT,
        format_version: FORMAT_VERSION,
        schema_version: DatabaseBackup.schema_version,
        created_at: Time.current.iso8601,
        tables:
      }
    end

    def table_json(table)
      # Let PostgreSQL serialize the rows, so all types (numeric, timestamps, ...) round-trip exactly.
      connection.select_value(<<~SQL.squish)
        SELECT COALESCE(json_agg(row_data), '[]'::json) FROM #{connection.quote_table_name(table)} row_data
      SQL
    end

    def add_blob_files(add_file)
      ActiveStorage::Blob.find_each do |blob|
        add_file.call("storage/#{blob.key}", blob.download)
      rescue ActiveStorage::FileNotFoundError
        Rails.logger.warn("Backup: file for blob #{blob.key} not found, skipping")
      end
    end
  end
end
