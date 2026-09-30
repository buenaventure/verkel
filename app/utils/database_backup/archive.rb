# frozen_string_literal: true

require 'rubygems/package'

module DatabaseBackup
  # Reads and writes the gzipped tar archive of a backup.
  module Archive
    class << self
      # Yields a block to add files with and returns the archive as binary string.
      def write
        buffer = StringIO.new(+'', 'wb')
        gzip = Zlib::GzipWriter.new(buffer)
        Gem::Package::TarWriter.new(gzip) do |tar|
          yield lambda { |name, content|
            content = content.b
            tar.add_file_simple(name, 0o644, content.bytesize) { it.write(content) }
          }
        end
        gzip.close
        buffer.string
      end

      # Returns all files of the archive as hash of name => content.
      def read(io)
        io.binmode if io.respond_to?(:binmode)
        entries = {}
        Zlib::GzipReader.wrap(io) do |gzip|
          Gem::Package::TarReader.new(gzip) do |tar|
            tar.each { entries[it.full_name] = (it.read || +'').force_encoding(Encoding::UTF_8) if it.file? }
          end
        end
        entries
      rescue Zlib::Error, Gem::Package::Error, Gem::Package::TarReader::UnexpectedEOF, EOFError
        raise Error, 'Die Datei ist kein gültiges Backup.'
      end
    end
  end
end
