# frozen_string_literal: true

# A small but complete planning data set for the API specs. The participant carries
# a comment and an external id, and the records carry LAMA uuids, so the specs can
# check that none of it leaves the app. The records are referenced by the including specs.
# rubocop:disable-next RSpec/LetSetup
RSpec.shared_context 'with api data' do
  let(:api_user) { create(:user, role: :read_only) }
  let(:api_token) { create(:api_token, user: api_user) }
  let(:Authorization) { "Bearer #{api_token.plain_token}" } # rubocop:disable RSpec/VariableName -- rswag's header name

  let!(:diet) { create(:diet, name: 'Vegan', lama_uuid: 'diet-lama-secret') }
  let!(:group) { create(:group, lama_uuid: 'group-lama-secret') }
  let!(:participant) do
    create(:participant, group:, age: 31, diets: [diet],
                         comment: 'Nussallergie, Name: Erika Mustermann',
                         external_id: 'EXT-SECRET-42', lama_uuid: 'participant-lama-secret')
  end
  let!(:group_change) { create(:group_change, participant:, group: create(:group)) }
  let!(:recipe) do
    create(:recipe, lama_uuid: 'recipe-lama-secret',
                    content: "**500 g Nudeln**\n\n**200 g Tofu (+Vegan)**\n\n**200 g Käse (-Vegan)**")
  end
  # Meals often have no name of their own, so the schemas must allow null.
  let!(:meal) { create(:meal, recipe:, name: nil, lama_slot_uuid: 'meal-lama-secret') }

  let(:secret_values) do
    ['Nussallergie', 'Erika Mustermann', 'EXT-SECRET-42', 'diet-lama-secret', 'group-lama-secret',
     'participant-lama-secret', 'recipe-lama-secret', 'meal-lama-secret', api_user.email]
  end
end
