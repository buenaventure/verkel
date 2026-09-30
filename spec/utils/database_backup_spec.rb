# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DatabaseBackup do
  let(:admin) { create(:user, email: 'admin@example.com', password: 'old-password', role: :admin) }
  let(:other_user) { create(:user, email: 'laga@example.com', password: 'laga-password', role: :laga) }
  let(:article) { create(:article, unit: 'g', price: BigDecimal('0.12345'), notes: 'Ümlaute & "Zeichen"') }

  def restore(backup, keep_user: admin)
    described_class.restore(StringIO.new(backup), keep_user:)
  end

  def restore_ignoring_errors(backup)
    restore(backup)
  rescue DatabaseBackup::Error
    nil
  end

  def backup_entries
    entries = {}
    Zlib::GzipReader.wrap(StringIO.new(described_class.create)) do |gzip|
      Gem::Package::TarReader.new(gzip) { |tar| tar.each { entries[it.full_name] = it.read || '' } }
    end
    entries
  end

  def backup_with_manifest(**changes)
    entries = backup_entries
    manifest = JSON.parse(entries['manifest.json']).merge(changes.stringify_keys)
    entries['manifest.json'] = manifest.to_json
    tar_gz(entries)
  end

  def tar_gz(entries)
    buffer = StringIO.new(+'', 'wb')
    gzip = Zlib::GzipWriter.new(buffer)
    Gem::Package::TarWriter.new(gzip) do |tar|
      entries.each { |name, content| tar.add_file_simple(name, 0o644, content.bytesize) { it.write(content) } }
    end
    gzip.close
    buffer.string
  end

  describe '.create' do
    it 'creates a gzipped tar archive with a manifest' do
      manifest = JSON.parse(backup_entries['manifest.json'])
      expect(manifest).to include('format' => 'verkel-backup', 'tables' => include('articles', 'users'))
    end
  end

  describe '.restore' do
    before do
      admin
      StockChange.create!(article:, user: other_user, quantity: 1, result: 1)
      Supplier.find(article.supplier_id).update!(notes: '<b>Notiz</b>')
    end

    it 'restores changed records' do
      backup = described_class.create
      original = article.attributes
      article.update!(price: 1, notes: 'geändert')
      restore(backup)
      expect(Article.find(article.id).attributes).to eq(original)
    end

    it 'restores deleted records including their associations' do
      backup = described_class.create
      StockChange.delete_all
      article.destroy!
      restore(backup)
      expect(StockChange.sole).to have_attributes(article_id: article.id, user_id: other_user.id)
    end

    it 'restores rich texts' do
      backup = described_class.create
      Supplier.find(article.supplier_id).update!(notes: 'neu')
      restore(backup)
      expect(Supplier.find(article.supplier_id).notes.body.to_html).to include('<b>Notiz</b>')
    end

    it 'removes records created after the backup' do
      backup = described_class.create
      create(:supplier, name: 'Neuer Lieferant')
      restore(backup)
      expect(Supplier.find_by(name: 'Neuer Lieferant')).to be_nil
    end

    it 'resets sequences so new records can be created' do
      backup = described_class.create
      restore(backup)
      expect { create(:supplier) }.to change(Supplier, :count).by(1)
    end

    it 'restores other accounts to the state of the backup' do
      backup = described_class.create
      other_user.update!(password: 'new-password')
      restore(backup)
      expect(User.find_by(email: 'laga@example.com').valid_password?('laga-password')).to be true
    end

    it 'keeps the current password of the restoring admin' do
      backup = described_class.create
      admin.update!(password: 'new-password')
      restore(backup)
      expect(User.find_by(email: 'admin@example.com').valid_password?('new-password')).to be true
    end

    it 'unlocks the restoring account' do
      other_user.update!(role: :admin, locked_at: Time.current, failed_attempts: 5)
      backup = described_class.create
      restored = restore(backup, keep_user: other_user)
      expect(restored.reload).to have_attributes(role: 'admin', locked_at: nil, failed_attempts: 0)
    end

    it 'grants admin rights to the restoring account if it had none in the backup' do
      backup = described_class.create
      other_user.update!(role: :admin)
      restored = restore(backup, keep_user: other_user)
      expect(restored.reload).to be_admin
    end

    it 'creates the restoring account if it does not exist in the backup' do
      admin.destroy!
      backup = described_class.create
      new_admin = create(:user, email: 'new-admin@example.com', password: 'secret123', role: :admin)
      restored = restore(backup, keep_user: new_admin)
      expect(User.find_by(email: 'new-admin@example.com')).to have_attributes(id: restored.id, role: 'admin')
    end

    it 'restores the password of the account created for the restoring admin' do
      admin.destroy!
      backup = described_class.create
      new_admin = create(:user, email: 'new-admin@example.com', password: 'secret123', role: :admin)
      restore(backup, keep_user: new_admin)
      expect(User.find_by(email: 'new-admin@example.com').valid_password?('secret123')).to be true
    end

    it 'restores Active Storage files' do
      blob = ActiveStorage::Blob.create_and_upload!(io: StringIO.new('Dateiinhalt'), filename: 'test.txt')
      backup = described_class.create
      blob.purge
      restore(backup)
      expect(ActiveStorage::Blob.find_by(key: blob.key).download).to eq('Dateiinhalt')
    end

    it 'deletes files of blobs not contained in the backup' do
      backup = described_class.create
      blob = ActiveStorage::Blob.create_and_upload!(io: StringIO.new('neu'), filename: 'neu.txt')
      restore(backup)
      expect(blob.service.exist?(blob.key)).to be false
    end

    it 'rejects files that are no backups' do
      expect { restore('kein Backup') }.to raise_error(DatabaseBackup::Error, /kein gültiges Backup/)
    end

    it 'rejects archives without manifest' do
      expect { restore(tar_gz('foo.txt' => 'bar')) }.to raise_error(DatabaseBackup::Error, /kein gültiges Backup/)
    end

    it 'rejects backups of newer schema versions' do
      backup = backup_with_manifest(schema_version: 99_999_999_999_999)
      expect { restore(backup) }.to raise_error(DatabaseBackup::Error, /neueren Version/)
    end

    it 'rejects backups with invalid table data' do
      backup = tar_gz(backup_entries.merge('tables/articles.json' => 'kaputt'))
      expect { restore(backup) }.to raise_error(DatabaseBackup::Error, /konnte nicht eingespielt werden/)
    end

    it 'leaves the data untouched when the backup cannot be imported' do
      backup = tar_gz(backup_entries.merge('tables/articles.json' => 'kaputt'))
      article.update!(notes: 'unverändert')
      expect { restore_ignoring_errors(backup) }.not_to(change { article.reload.notes })
    end

    it 'ignores columns missing in the backup' do
      tables = JSON.parse(backup_entries['manifest.json'])['tables']
      tables['articles'] -= ['notes']
      backup = backup_with_manifest(tables:)
      restore(backup)
      expect(Article.find(article.id).notes).to be_nil
    end
  end
end
