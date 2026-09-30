# frozen_string_literal: true

require 'swagger_helper'

RSpec.describe 'Meals API' do
  include_context 'with api data'

  path '/meals.json' do
    get 'List meals' do
      tags 'Meals'
      description 'All meals in time order, with their recipe and the total number of servings.'
      produces 'application/json'

      response '200', 'meals' do
        schema ApiSchemas.envelope(ApiSchemas.list(:meals, ApiSchemas.ref(:MealSummary)))
        run_test! do |response|
          expect(response.parsed_body.dig('data', 'meals', 0, 'servings')).to eq(1)
        end
      end

      response '401', 'missing, unknown, expired or revoked token' do
        let(:Authorization) { 'Bearer verkel_unknown' } # rubocop:disable RSpec/VariableName
        schema ApiSchemas.ref(:Error)
        run_test!
      end
    end
  end

  path '/meals/{id}.json' do
    parameter name: :id, in: :path, type: :integer

    get 'Show a meal' do
      tags 'Meals'
      description 'One meal with its recipe, box and the servings each Kochgruppe needs.'
      produces 'application/json'

      response '200', 'meal' do
        let(:id) { meal.id }
        schema ApiSchemas.envelope(ApiSchemas.object(meal: ApiSchemas.ref(:Meal)))
        run_test! do |response|
          # The group change covers the meal, so the participant eats with the other group.
          servings = response.parsed_body.dig('data', 'meal', 'servings_per_group')
          expect(servings.to_h { [it.dig('group', 'id'), it['servings']] })
            .to eq(group.id => 0, group_change.group_id => 1)
        end
      end

      response '404', 'no such meal' do
        let(:id) { 0 }
        run_test!
      end
    end
  end
end
