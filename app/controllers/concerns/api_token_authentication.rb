# frozen_string_literal: true

# Signs a request in with an API token from the `Authorization: Bearer …` header.
#
# A request carrying a bearer token is authenticated by that token alone, even if it
# also carries a session cookie: Warden would otherwise pick the session user first and
# the token's scope would never apply. Token requests must ask for JSON, never write a
# session and skip CSRF protection (browsers can't add an Authorization header to a
# cross-site request without a CORS preflight, which this app never allows).
module ApiTokenAuthentication
  extend ActiveSupport::Concern

  RATE_LIMIT = 120
  RATE_LIMIT_PERIOD = 1.minute

  included do
    prepend_before_action :authenticate_api_token!, if: :api_token_request?
    skip_forgery_protection if: :api_token_request?
    before_action :enforce_api_token_scope!, if: :current_api_token
    rate_limit to: RATE_LIMIT, within: RATE_LIMIT_PERIOD,
               by: -> { current_api_token.id },
               with: -> { render json: { error: 'Zu viele Anfragen' }, status: :too_many_requests },
               store: Rails.application.config.x.api_rate_limit_store || Rails.cache,
               scope: 'api_token',
               if: :current_api_token

    helper_method :current_api_token
  end

  def current_api_token
    @current_api_token
  end

  private

  def api_token_request?
    bearer_token.present? && !devise_controller?
  end

  def bearer_token
    return @bearer_token if defined?(@bearer_token)

    @bearer_token = request.authorization.to_s[/\ABearer +(\S+)\z/i, 1]
  end

  def authenticate_api_token!
    request.session_options[:skip] = true
    return head :not_acceptable unless request.format.json?

    @current_api_token = ApiToken.authenticate(bearer_token)
    throw :warden, scope: :user, message: :invalid_token unless @current_api_token

    # event :fetch still runs Devise's lockable check but skips trackable and the CSRF reset.
    warden.set_user(@current_api_token.user, scope: :user, store: false, event: :fetch)
    @current_api_token.touch_last_used
  end

  def enforce_api_token_scope!
    return if request.get? || request.head? || current_api_token.write?

    render json: { error: 'Dieses Token darf nur lesen' }, status: :forbidden
  end
end
