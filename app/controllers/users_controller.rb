class UsersController < ApplicationController
  load_and_authorize_resource

  def index; end

  def new; end

  def edit; end

  def create
    respond_to do |format|
      if @user.save
        format.html { redirect_to @user, notice: 'Benutzer wurde erfolgreich erstellt.' }
      else
        format.html { render :new, status: :unprocessable_content }
      end
    end
  end

  def update
    respond_to do |format|
      if @user.update(user_params)
        format.html { redirect_to @user, notice: 'Benutzer wurde erfolgreich aktualisiert.' }
      else
        format.html { render :edit, status: :unprocessable_content }
      end
    end
  end

  def destroy
    respond_to do |format|
      if @user.destroy
        format.html { redirect_to users_url, notice: 'Benutzer wurde erfolgreich gelöscht.', status: :see_other }
      else
        format.html do
          redirect_to @user, status: :see_other, alert: @user.errors.full_messages
        end
      end
    end
  end

  private

  def user_params
    params.expect(user: %i[email password role])
  end
end
