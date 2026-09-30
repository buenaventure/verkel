# frozen_string_literal: true

module ApiHelpers
  def api_headers(api_token)
    { 'Authorization' => "Bearer #{api_token.plain_token}", 'Accept' => 'application/json' }
  end
end

RSpec.configure do |config|
  config.include ApiHelpers, type: :request
end
