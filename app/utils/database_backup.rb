# frozen_string_literal: true

# Creates and restores full backups of the application data.
#
# A backup is a gzipped tar archive containing
# - manifest.json: format info, schema version and the columns of each table
# - tables/<table>.json: all rows of a table, serialized by PostgreSQL
# - storage/<key>: the files of all Active Storage blobs (e.g. rich text attachments)
module DatabaseBackup
  class Error < StandardError; end

  FORMAT = 'verkel-backup'
  FORMAT_VERSION = 1
  MANIFEST_FILE = 'manifest.json'
  EXCLUDED_TABLES = %w[schema_migrations ar_internal_metadata].freeze

  class << self
    def filename(time = Time.current)
      "verkel-backup-#{time.strftime('%Y%m%d-%H%M%S')}.tar.gz"
    end

    # Returns the backup as binary string.
    def create
      Export.new.run
    end

    # Replaces all data with the contents of the backup.
    #
    # The account of +keep_user+ survives the restore with its current password and admin role,
    # so the person restoring the backup is not locked out. Returns that (restored) user.
    def restore(io, keep_user:)
      Import.new(io).run(keep_user:)
    end

    def data_tables
      ActiveRecord::Base.connection.tables - EXCLUDED_TABLES
    end

    def schema_version
      ActiveRecord::Base.connection_pool.migration_context.current_version
    end
  end
end
