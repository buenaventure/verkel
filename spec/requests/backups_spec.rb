# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Backups' do
  let(:user) { create(:user, role: :admin, password: 'password123') }

  before { sign_in user, scope: :user }

  describe 'GET /backup' do
    it 'shows the backup page' do
      get backup_path
      expect(response).to have_http_status(:ok)
    end

    %i[office laga read_only].each do |role|
      context "when the user is #{role}" do
        let(:user) { create(:user, role:) }

        it 'denies access' do
          get backup_path
          expect(response).to redirect_to(root_path)
        end
      end
    end
  end

  describe 'GET /backup/download' do
    it 'sends a backup file' do
      get download_backup_path
      expect(response.headers['Content-Disposition']).to match(/attachment; filename="verkel-backup-.*\.tar\.gz"/)
    end

    context 'when the user is office' do
      let(:user) { create(:user, role: :office) }

      it 'denies access' do
        get download_backup_path
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe 'POST /backup/restore' do
    let!(:supplier) { create(:supplier, name: 'Vorher') }

    def upload(content, confirm: '1')
      file = Tempfile.new(%w[backup .tar.gz]).tap do |f|
        f.binmode
        f.write(content)
        f.rewind
      end
      post restore_backup_path,
           params: { backup_file: Rack::Test::UploadedFile.new(file.path, 'application/gzip', true), confirm: }
    end

    it 'restores the backup' do
      backup = DatabaseBackup.create
      supplier.update!(name: 'Nachher')
      upload(backup)
      expect(supplier.reload.name).to eq('Vorher')
    end

    it 'keeps the admin signed in' do
      backup = DatabaseBackup.create
      upload(backup)
      follow_redirect!
      expect(response.body).to include('Backup wurde erfolgreich eingespielt')
    end

    it 'keeps the admin signed in when their account is created anew' do
      backup = DatabaseBackup.create
      user.update!(email: 'not-in-backup@example.com')
      upload(backup)
      follow_redirect!
      expect(response).to have_http_status(:ok)
    end

    it 'requires confirmation' do
      backup = DatabaseBackup.create
      supplier.update!(name: 'Nachher')
      upload(backup, confirm: '0')
      expect(supplier.reload.name).to eq('Nachher')
    end

    it 'shows an error for invalid files' do
      upload('kein Backup')
      follow_redirect!
      expect(response.body).to include('kein gültiges Backup')
    end

    context 'when the user is office' do
      let(:user) { create(:user, role: :office) }

      it 'denies access' do
        backup = DatabaseBackup.create
        supplier.update!(name: 'Nachher')
        upload(backup)
        expect(supplier.reload.name).to eq('Nachher')
      end
    end
  end
end
