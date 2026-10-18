# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PaddedNameCleanup do
  let(:log) { StringIO.new }

  # Ingredient and Diet strip names whenever they are cast or serialized, so
  # padded names (as saved before that) need raw SQL.
  def padded(record, name)
    record.class.where(id: record.id).update_all(['name = ?', name]) # rubocop:disable Rails/SkipsModelValidations
    record
  end

  def run(apply: true)
    described_class.new(apply:, log:).call
  end

  context 'when the stripped name is free' do
    let!(:ingredient) { padded(create(:ingredient), 'Mandeln ') }

    it 'renames the record' do
      expect { run }.to change { ingredient.reload.name }.to('Mandeln')
    end

    it 'changes nothing on a dry run', :aggregate_failures do
      run(apply: false)

      expect(ingredient.reload.name).to eq('Mandeln ')
      expect(log.string).to include('[Probelauf] Zutat')
    end
  end

  context 'when the stripped ingredient name is taken' do
    let!(:mandeln) { create(:ingredient, name: 'Mandeln') }
    let!(:recipe) { Recipe.create!(name: 'test', content: '**5 g Mandeln**') }
    let!(:duplicate) { padded(create(:ingredient), 'Mandeln ') }

    before { recipe.recipe_ingredients.first.update!(ingredient: duplicate) }

    it 'moves recipe ingredients onto the twin and removes the duplicate', :aggregate_failures do
      run

      expect(recipe.reload.ingredients).to eq([mandeln])
      expect(Ingredient.exists?(duplicate.id)).to be(false)
    end

    it 'skips a duplicate that is used outside of recipes', :aggregate_failures do
      create(:article, ingredient: duplicate, unit: 'g')

      run

      expect(duplicate.reload.name).to eq('Mandeln ')
      expect(log.string).to include('übersprungen, wird noch verwendet von: articles')
    end
  end

  context 'when the stripped diet name is taken' do
    let!(:vegan) { create(:diet, name: 'vegan') }
    let!(:recipe) { Recipe.create!(name: 'test', content: '**5 g Mandeln (+vegan)**') }
    let!(:duplicate) { padded(create(:diet), 'vegan ') }

    before { PositiveDietIngredient.update_all(diet_id: duplicate.id) } # rubocop:disable Rails/SkipsModelValidations

    it 'moves the recipe diets onto the twin and removes the duplicate', :aggregate_failures do
      run

      expect(recipe.recipe_ingredients.first.positive_diets).to eq([vegan])
      expect(Diet.exists?(duplicate.id)).to be(false)
    end
  end
end
