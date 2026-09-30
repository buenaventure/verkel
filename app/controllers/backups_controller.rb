# frozen_string_literal: true

# Lets admins download a backup of all data and restore the application to the state of a backup.
class BackupsController < ApplicationController
  authorize_resource :backup, class: false
  before_action :set_breadcrumbs
  before_action :check_restore_params, only: :restore

  def show; end

  def download
    send_data DatabaseBackup.create,
              filename: DatabaseBackup.filename,
              type: 'application/gzip',
              disposition: 'attachment'
  end

  def restore
    user = DatabaseBackup.restore(params.expect(:backup_file).tempfile, keep_user: current_user)
    bypass_sign_in(user, scope: :user)
    redirect_to_backup(notice: t('.success'))
  rescue DatabaseBackup::Error => e
    redirect_to_backup(alert: e.message)
  end

  private

  def check_restore_params
    if params[:backup_file].blank?
      redirect_to_backup(alert: t('backups.restore.file_missing'))
    elsif params[:confirm] != '1'
      redirect_to_backup(alert: t('backups.restore.not_confirmed'))
    end
  end

  def redirect_to_backup(flash)
    redirect_to backup_path, status: :see_other, **flash
  end

  def set_breadcrumbs
    @breadcrumbs = [['Backup', backup_path]]
  end
end
