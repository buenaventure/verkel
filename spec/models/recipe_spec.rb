require 'rails_helper'

RSpec.describe Recipe do
  context 'ingredient parsing' do
    it 'creates ingredients on create' do
      expect(described_class.create!(name: 'test', content: 'test').recipe_ingredients).to be_empty
      recipe_ingredients = described_class.create!(name: 'test2',
                                                   content: '**5 g Zucker** **2 ml Honig**').recipe_ingredients
      expect(recipe_ingredients.size).to eq(2)
      expect(recipe_ingredients[0].quantity).to eq(5)
      expect(recipe_ingredients[0].unit).to eq('g')
      expect(recipe_ingredients[0].ingredient.name).to eq('Zucker')
      expect(recipe_ingredients[1].quantity).to eq(2)
      expect(recipe_ingredients[1].unit).to eq('ml')
      expect(recipe_ingredients[1].ingredient.name).to eq('Honig')
    end

    it 'normalizes units' do
      recipe_ingredients = described_class.create!(name: 'test',
                                                   content: '**1 l Wasser** **1 kg Mehl**').recipe_ingredients
      expect(recipe_ingredients.size).to eq(2)
      expect(recipe_ingredients[0].quantity).to eq(1000)
      expect(recipe_ingredients[0].unit).to eq('ml')
      expect(recipe_ingredients[0].ingredient.name).to eq('Wasser')
      expect(recipe_ingredients[1].quantity).to eq(1000)
      expect(recipe_ingredients[1].unit).to eq('g')
      expect(recipe_ingredients[1].ingredient.name).to eq('Mehl')
    end

    context 'update' do
      it 'updates recipe_ingredients without creating new records' do
        recipe = described_class.create!(name: 'test', content: '**5 g Zucker**')
        existing_recipe_ingredient_id = recipe.recipe_ingredients[0].id
        recipe.content = '**5 g Zucker** **10 g Mehl**'
        recipe.save!
        expect(recipe.ingredients.size).to eq(2)
        recipe_ingredients = recipe.recipe_ingredients
        expect(recipe_ingredients[0].id).to be(existing_recipe_ingredient_id)
        expect(recipe_ingredients[0].quantity).to eq(5)
        expect(recipe_ingredients[0].unit).to eq('g')
        expect(recipe_ingredients[0].ingredient.name).to eq('Zucker')
        expect(recipe_ingredients[1].quantity).to eq(10)
        expect(recipe_ingredients[1].unit).to eq('g')
        expect(recipe_ingredients[1].ingredient.name).to eq('Mehl')
      end

      it 'removes ingredients' do
        recipe = described_class.create!(name: 'test', content: '**5 g Zucker**')
        recipe.content = 'nix'
        recipe.save!
        expect(recipe.ingredients.size).to eq(0)
      end
    end
  end
end
