# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'API token authentication' do
  let(:user) { create(:user, role: :read_only) }
  let(:api_token) { create(:api_token, user:) }

  it 'answers 401 JSON without credentials', :aggregate_failures do
    get meals_path(format: :json)
    expect(response).to have_http_status(:unauthorized)
    expect(response.parsed_body).to have_key('error')
  end

  it 'answers 200 with a valid token', :aggregate_failures do
    get meals_path(format: :json), headers: api_headers(api_token)
    expect(response).to have_http_status(:ok)
    expect(response.parsed_body).to include('data', 'meta')
  end

  it 'accepts JSON asked for through the Accept header' do
    get meals_path, headers: api_headers(api_token)
    expect(response.media_type).to eq('application/json')
  end

  it 'answers 401 for an unknown token', :aggregate_failures do
    get meals_path(format: :json), headers: { 'Authorization' => 'Bearer verkel_nope' }
    expect(response).to have_http_status(:unauthorized)
    expect(response.parsed_body['error']).to eq(I18n.t('devise.failure.invalid_token'))
  end

  it 'answers 401 for a revoked token' do
    api_token.revoke!
    get meals_path(format: :json), headers: api_headers(api_token)
    expect(response).to have_http_status(:unauthorized)
  end

  it 'answers 401 for an expired token' do
    api_token.update!(expires_at: 1.minute.ago)
    get meals_path(format: :json), headers: api_headers(api_token)
    expect(response).to have_http_status(:unauthorized)
  end

  it 'answers 401 when the token user is locked' do
    user.lock_access!(send_instructions: false)
    get meals_path(format: :json), headers: api_headers(api_token)
    expect(response).to have_http_status(:unauthorized)
  end

  it 'answers 406 when a token asks for HTML' do
    get meals_path, headers: { 'Authorization' => "Bearer #{api_token.plain_token}" }
    expect(response).to have_http_status(:not_acceptable)
  end

  it 'writes no session cookie' do
    get meals_path(format: :json), headers: api_headers(api_token)
    expect(response.headers['Set-Cookie']).to be_nil
  end

  it 'leaves the Devise sign-in tracking untouched' do
    expect { get meals_path(format: :json), headers: api_headers(api_token) }
      .not_to(change { user.reload.sign_in_count })
  end

  it 'records when the token was last used' do
    expect { get meals_path(format: :json), headers: api_headers(api_token) }
      .to change { api_token.reload.last_used_at }.from(nil)
  end

  it 'acts as the token user even when a session cookie of another user comes along' do
    sign_in create(:user, role: :admin), scope: :user
    get users_path(format: :json), headers: api_headers(api_token)
    expect(response).to have_http_status(:forbidden)
  end

  describe 'scope' do
    it 'refuses writes for a read token', :aggregate_failures do
      meal = create(:meal)
      admin_token = create(:api_token, user: create(:user, role: :admin))
      expect { delete meal_path(meal, format: :json), headers: api_headers(admin_token) }
        .not_to change(Meal, :count)
      expect(response).to have_http_status(:forbidden)
      expect(response.parsed_body).to have_key('error')
    end

    it 'lets a write token through to the role check' do
      write_token = create(:api_token, user:, scopes: %w[read write])
      delete meal_path(create(:meal), format: :json), headers: api_headers(write_token)
      expect(response).to have_http_status(:forbidden) # read_only role may not destroy meals
    end
  end

  describe 'role' do
    it 'refuses what the role may not read, with a JSON body', :aggregate_failures do
      get group_spendings_path(format: :json), headers: api_headers(api_token)
      expect(response).to have_http_status(:forbidden)
      expect(response.parsed_body).to have_key('error')
    end

    it 'follows role changes of the token user' do
      user.update!(role: :office)
      get meals_path(format: :json), headers: api_headers(api_token)
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'users' do
    it 'are forbidden for non-admins' do
      get users_path(format: :json), headers: api_headers(api_token)
      expect(response).to have_http_status(:forbidden)
    end

    it 'have no JSON representation even for admins' do
      admin_token = create(:api_token, user: create(:user, role: :admin))
      get users_path(format: :json), headers: api_headers(admin_token)
      expect(response).to have_http_status(:not_acceptable)
    end
  end

  it 'rate limits each token', :aggregate_failures do
    ApiTokenAuthentication::RATE_LIMIT.times { get openapi_path, headers: api_headers(api_token) }
    expect(response).to have_http_status(:ok)
    get openapi_path, headers: api_headers(api_token)
    expect(response).to have_http_status(:too_many_requests)
  end
end
