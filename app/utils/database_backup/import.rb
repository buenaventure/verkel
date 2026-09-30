# frozen_string_literal: true

module DatabaseBackup
  # Replaces all data with the contents of a backup archive.
  class Import
    def initialize(io)
      @entries = Archive.read(io)
      @manifest = parse_manifest
    end

    def run(keep_user:)
      removing_orphaned_blob_files do
        connection.transaction do
          restore_tables
          refresh_calculations
          restore_blob_files
          restore_account(keep_user)
        end
      end
    rescue ActiveRecord::StatementInvalid, ActiveRecord::RecordInvalid, ActiveStorage::IntegrityError => e
      raise Error, "Das Backup konnte nicht eingespielt werden: #{e.message.truncate(300)}"
    end

    private

    def connection
      ActiveRecord::Base.connection
    end

    def parse_manifest
      manifest = JSON.parse(@entries.fetch(MANIFEST_FILE))
      raise Error, 'Die Datei ist kein gültiges Backup.' unless manifest['format'] == FORMAT
      if manifest['format_version'].to_i > FORMAT_VERSION ||
         manifest['schema_version'].to_i > DatabaseBackup.schema_version
        raise Error, 'Das Backup stammt von einer neueren Version von VerKeL und kann nicht importiert werden.'
      end

      manifest
    rescue KeyError, JSON::ParserError
      raise Error, 'Die Datei ist kein gültiges Backup.'
    end

    def restore_tables
      tables = DatabaseBackup.data_tables
      connection.execute("TRUNCATE #{tables.map { connection.quote_table_name(it) }.join(', ')}")
      TableOrder.new(tables).to_a.each { restore_table(it) }
      tables.each { connection.reset_pk_sequence!(it) }
    end

    def restore_table(table)
      json = @entries["tables/#{table}.json"]
      backup_columns = @manifest.fetch('tables')[table]
      return if json.nil? || backup_columns.nil?

      # Columns added after the backup was created get their default values.
      insert_rows(table, connection.columns(table).map(&:name) & backup_columns, json)
    end

    def insert_rows(table, columns, json)
      quoted_table = connection.quote_table_name(table)
      column_list = columns.map { connection.quote_column_name(it) }.join(', ')
      connection.execute(<<~SQL.squish)
        INSERT INTO #{quoted_table} (#{column_list})
        SELECT #{column_list} FROM json_populate_recordset(NULL::#{quoted_table}, #{connection.quote(json)}::json)
      SQL
    end

    def refresh_calculations
      Calculation.calculatables.each { Calculation.find_or_create_by!(id: it.calculatable_name) }
      connection.select_values(<<~SQL.squish).each do |view|
        SELECT matviewname FROM pg_matviews WHERE schemaname = ANY(current_schemas(false))
      SQL
        Scenic.database.refresh_materialized_view(view, concurrently: false, cascade: false)
      end
    end

    def restore_blob_files
      ActiveStorage::Blob.find_each do |blob|
        content = @entries["storage/#{blob.key}"]
        next if content.nil?

        blob.service.upload(blob.key, StringIO.new(content.b), checksum: blob.checksum)
      end
    end

    # Makes sure the admin restoring the backup can still log in afterwards.
    # +account+ is the user loaded before the restore, so it still holds the current email and password.
    def restore_account(account)
      user = User.find_or_initialize_by(email: account.email)
      user.encrypted_password = account.encrypted_password
      user.role = :admin
      user.failed_attempts = 0
      user.locked_at = nil
      user.save!(validate: false)
      user
    end

    # Deletes files of blobs that no longer exist after the restore.
    def removing_orphaned_blob_files
      old_keys = ActiveStorage::Blob.pluck(:key)
      result = yield
      (old_keys - ActiveStorage::Blob.pluck(:key)).each { ActiveStorage::Blob.service.delete(it) }
      result
    end
  end
end
