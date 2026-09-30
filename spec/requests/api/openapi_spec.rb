# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'API description' do
  it 'serves the OpenAPI description to tokens', :aggregate_failures do
    get openapi_path, headers: api_headers(create(:api_token))
    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.dig('info', 'title')).to eq('VerKeL API')
    expect(response.parsed_body['paths']).to include('/meals.json', '/participants/{id}.json')
  end

  it 'serves the OpenAPI description to signed-in users' do
    sign_in create(:user), scope: :user
    get openapi_path
    expect(response).to have_http_status(:ok)
  end

  it 'is not public' do
    get openapi_path
    expect(response).to have_http_status(:unauthorized)
  end

  describe 'docs UI' do
    it 'is shown to signed-in users' do
      sign_in create(:user), scope: :user
      get '/api-docs/index.html'
      expect(response.body).to include('/openapi.json')
    end

    it 'sends anyone else to the sign-in page' do
      get '/api-docs/index.html'
      expect(response).to redirect_to('/users/sign_in')
    end
  end
end
