# frozen_string_literal: true

require 'rails_helper'

# Guards the templates as allowlists: whatever a new field or partial does, none of these
# keys and none of the planted values may appear in any JSON response.
RSpec.describe 'API data exposure' do
  include_context 'with api data'

  let(:forbidden_keys) do
    %w[comment external_id lama_uuid lama_slot_uuid email phone address notes
       encrypted_password token_digest user_id budget]
  end
  let(:api_user) { create(:user, role: :admin) }

  def endpoints
    [
      meals_path(format: :json), meal_path(meal, format: :json),
      recipes_path(format: :json), recipe_path(recipe, format: :json),
      participants_path(format: :json), participant_path(participant, format: :json)
    ]
  end

  def keys_in(value)
    case value
    when Hash then value.keys + value.values.flat_map { keys_in(it) }
    when Array then value.flat_map { keys_in(it) }
    else []
    end
  end

  it 'never sends personal fields or identifiers from other systems', :aggregate_failures do
    endpoints.each do |path|
      get path, headers: api_headers(api_token)
      expect(response).to have_http_status(:ok), path
      expect(keys_in(response.parsed_body) & forbidden_keys).to be_empty, path
      secret_values.each { |value| expect(response.body).not_to include(value), "#{path} leaks #{value}" }
    end
  end
end
