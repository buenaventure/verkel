# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Recipes' do
  let(:user) { create(:user, role: :office) }

  before do
    sign_in user, scope: :user
  end

  describe 'GET /recipes/new' do
    def autocomplete_value(name)
      wrapper = response.parsed_body.at_css('[data-controller="recipe-ingredient-autocomplete"]')
      JSON.parse(wrapper["data-recipe-ingredient-autocomplete-#{name}-value"])
    end

    before do
      create(:ingredient, name: 'Mehl')
      create(:diet, name: 'vegan')
    end

    it 'passes units, ingredients and diets to the autocomplete', :aggregate_failures do
      get new_recipe_path

      expect(autocomplete_value('units')).to include('g', 'kg', 'ml', 'l')
      expect(autocomplete_value('ingredients')).to include('Mehl')
      expect(autocomplete_value('diets')).to include('vegan')
    end
  end

  describe 'POST /recipes' do
    it 'shows a form error for an unparseable ingredient instead of failing', :aggregate_failures do
      post recipes_path, params: { recipe: { name: 'Brot', content: '**500 g Mehl** und **Salz**' } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include('ungültige Zutat „Salz“')
      expect(Recipe.count).to eq(0)
    end
  end

  describe 'PATCH /recipes/:id' do
    it 'shows a form error for an unparseable ingredient instead of failing', :aggregate_failures do
      recipe = Recipe.create!(name: 'Brot', content: '**500 g Mehl**')

      patch recipe_path(recipe), params: { recipe: { content: '**500 g Mehl** **etwas Salz**' } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include('ungültige Zutat „etwas Salz“')
      expect(recipe.reload.content).to eq('**500 g Mehl**')
    end
  end
end
