# frozen_string_literal: true

require 'swagger_helper'

RSpec.describe 'Recipes API' do
  include_context 'with api data'

  path '/recipes.json' do
    get 'List recipes' do
      tags 'Recipes'
      description 'All recipes by name, with the meals they are cooked for.'
      produces 'application/json'

      response '200', 'recipes' do
        schema ApiSchemas.envelope(ApiSchemas.list(:recipes, ApiSchemas.ref(:RecipeSummary)))
        run_test!
      end
    end
  end

  path '/recipes/{id}.json' do
    parameter name: :id, in: :path, type: :integer

    get 'Show a recipe' do
      tags 'Recipes'
      description <<~TEXT
        One recipe with its preparation text (Markdown) and ingredients. `positive_diets` limits
        an ingredient to participants with that diet (`+Diet` in the recipe), `negative_diets`
        leaves it out for them (`-Diet`).
      TEXT
      produces 'application/json'

      response '200', 'recipe' do
        let(:id) { recipe.id }
        schema ApiSchemas.envelope(ApiSchemas.object(recipe: ApiSchemas.ref(:Recipe)))
        run_test! do |response|
          ingredients = response.parsed_body.dig('data', 'recipe', 'ingredients')
          expect(ingredients.map { it.values_at('quantity', 'unit') }).to eq([[500.0, 'g'], [200.0, 'g'], [200.0, 'g']])
        end
      end
    end
  end
end
