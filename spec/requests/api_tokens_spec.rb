# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'API tokens' do
  let(:user) { create(:user, role: :read_only) }
  let!(:own_token) { create(:api_token, user:, name: 'Mein Token') }
  let!(:other_token) { create(:api_token, name: 'Fremdes Token') }

  context 'when signed in as a read-only user' do
    before { sign_in user, scope: :user }

    it 'lists only the own tokens', :aggregate_failures do
      get api_tokens_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Mein Token')
      expect(response.body).not_to include('Fremdes Token')
    end

    it 'offers a form with a 90 day default expiry' do
      get new_api_token_path
      expect(response.body).to include(90.days.from_now.to_date.iso8601)
    end

    it 'creates a read token for the user and shows it once', :aggregate_failures do
      expect { post api_tokens_path, params: { api_token: { name: 'Claude', expires_at: '' } } }
        .to change(user.api_tokens, :count).by(1)
      token = user.api_tokens.find_by!(name: 'Claude')
      expect(response).to have_http_status(:created)
      expect(token.scopes).to eq(['read'])
      expect(token.expires_at).to be_nil
      plain = response.body[/#{ApiToken::PREFIX}\w+/o]
      expect(ApiToken.authenticate(plain)).to eq(token)
    end

    it 'ignores attempts to create a token for someone else or with more scopes' do
      post api_tokens_path, params: { api_token: { name: 'Claude', user_id: other_token.user_id, scopes: ['write'] } }
      expect(user.api_tokens.find_by!(name: 'Claude').scopes).to eq(['read'])
    end

    it 'shows the form again without a name' do
      post api_tokens_path, params: { api_token: { name: '' } }
      expect(response).to have_http_status(:unprocessable_content)
    end

    it 'revokes an own token' do
      patch revoke_api_token_path(own_token)
      expect(own_token.reload.revoked_at).to be_present
    end

    it "can't revoke someone else's token" do
      patch revoke_api_token_path(other_token)
      expect(other_token.reload.revoked_at).to be_nil
    end
  end

  context 'when signed in as an office user' do
    before { sign_in create(:user, role: :office), scope: :user }

    it "doesn't see other users' tokens" do
      get api_tokens_path
      expect(response.body).not_to include('Fremdes Token')
    end

    it "can't revoke other users' tokens" do
      patch revoke_api_token_path(other_token)
      expect(other_token.reload.revoked_at).to be_nil
    end
  end

  context 'when signed in as an admin' do
    before { sign_in create(:user, role: :admin), scope: :user }

    it 'lists all tokens with their users', :aggregate_failures do
      get api_tokens_path
      expect(response.body).to include('Mein Token', 'Fremdes Token', user.email)
    end

    it "revokes other users' tokens" do
      patch revoke_api_token_path(other_token)
      expect(other_token.reload.revoked_at).to be_present
    end
  end

  context 'when using an API token' do
    let!(:write_token) { create(:api_token, user: create(:user, role: :admin), scopes: %w[read write]) }

    it 'refuses to list tokens' do
      get api_tokens_path(format: :json), headers: api_headers(write_token)
      expect(response).to have_http_status(:forbidden)
    end

    it 'refuses to create tokens' do
      expect do
        post api_tokens_path(format: :json), params: { api_token: { name: 'x' } }, headers: api_headers(write_token)
      end.not_to change(ApiToken, :count)
    end

    it 'refuses to revoke tokens' do
      patch revoke_api_token_path(own_token, format: :json), headers: api_headers(write_token)
      expect(own_token.reload.revoked_at).to be_nil
    end
  end
end
