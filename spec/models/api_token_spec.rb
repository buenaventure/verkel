# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApiToken do
  include ActiveSupport::Testing::TimeHelpers

  subject(:api_token) { create(:api_token) }

  it { is_expected.to belong_to(:user) }
  it { is_expected.to validate_presence_of(:name) }

  it 'shows the plain token only right after creation', :aggregate_failures do
    expect(api_token.plain_token).to start_with(ApiToken::PREFIX)
    expect(described_class.find(api_token.id).plain_token).to be_nil
  end

  it 'stores only the SHA-256 digest of the token' do
    expect(api_token.token_digest).to eq(OpenSSL::Digest::SHA256.hexdigest(api_token.plain_token))
  end

  it 'defaults to the read scope', :aggregate_failures do
    expect(api_token.scopes).to eq(['read'])
    expect(api_token).not_to be_write
  end

  it 'rejects unknown scopes' do
    expect(build(:api_token, scopes: %w[read admin])).not_to be_valid
  end

  describe '.authenticate' do
    it 'finds an active token by its plain value' do
      expect(described_class.authenticate(api_token.plain_token)).to eq(api_token)
    end

    it 'ignores blank and unknown values', :aggregate_failures do
      expect(described_class.authenticate(nil)).to be_nil
      expect(described_class.authenticate('verkel_unknown')).to be_nil
    end

    it 'ignores revoked tokens' do
      api_token.revoke!
      expect(described_class.authenticate(api_token.plain_token)).to be_nil
    end

    it 'ignores expired tokens' do
      api_token.update!(expires_at: 1.second.ago)
      expect(described_class.authenticate(api_token.plain_token)).to be_nil
    end
  end

  describe '#touch_last_used' do
    it 'writes at most once a minute', :aggregate_failures do
      api_token.touch_last_used
      first = api_token.reload.last_used_at
      api_token.touch_last_used
      expect(api_token.reload.last_used_at).to eq(first)
      travel 2.minutes do
        api_token.touch_last_used
        expect(api_token.reload.last_used_at).to be > first
      end
    end
  end
end
