# frozen_string_literal: true

# The "API-Tokens" page: users create, list and revoke their own tokens, admins all of them.
class ApiTokensController < ApplicationController
  DEFAULT_LIFETIME = 90.days

  before_action :refuse_api_token_requests
  load_and_authorize_resource

  def index
    @api_tokens = @api_tokens.includes(:user).order(created_at: :desc)
  end

  def new
    @api_token.expires_at = DEFAULT_LIFETIME.from_now.to_date
  end

  def create
    @api_token.user = current_user
    if @api_token.save
      render :created, status: :created
    else
      render :new, status: :unprocessable_content
    end
  end

  def revoke
    @api_token.revoke!
    redirect_to api_tokens_path, notice: "API-Token „#{@api_token}“ wurde widerrufen.", status: :see_other
  end

  private

  # Tokens are managed in the browser only, so a leaked token can't mint or revoke others.
  def refuse_api_token_requests
    return unless current_api_token

    render json: { error: 'API-Tokens können nicht über die API verwaltet werden' }, status: :forbidden
  end

  def api_token_params
    params.expect(api_token: %i[name expires_at])
  end
end
