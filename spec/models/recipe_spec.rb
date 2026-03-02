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

      it 'edits and removes ingredients in one update' do
        recipe = described_class.create!(name: 'test', content: '**5 g Zucker** **10 g Mehl**')
        original_first_id = recipe.recipe_ingredients.first.id

        # Change the first ingredient and drop the second one
        recipe.content = '**7 g Zucker**'
        recipe.save!

        recipe.reload
        expect(recipe.recipe_ingredients.size).to eq(1)
        edited = recipe.recipe_ingredients.first
        expect(edited.id).to eq(original_first_id)
        expect(edited.quantity).to eq(7)
        expect(edited.unit).to eq('g')
        expect(edited.ingredient.name).to eq('Zucker')
      end
    end

    it 'adds errors for disallowed units' do
      recipe = described_class.new(name: 'test', content: '**1 foo Zucker**')

      expect(recipe).not_to be_valid
      expect(recipe.recipe_ingredients.size).to eq(1)

      ingredient = recipe.recipe_ingredients.first
      expect(ingredient.errors[:unit]).to include('foo ist keine erlaubte Einheit')
      expect(recipe.errors[:recipe_ingredients]).to be_present
    end

    it 'keeps unsaved content and adds errors on update with disallowed units' do
      recipe = described_class.create!(name: 'test', content: '**1 g Zucker**')
      original_content = recipe.content

      recipe.content = '**1 foo Zucker**'
      expect(recipe).not_to be_valid

      # content on the in-memory recipe stays as the user entered it
      expect(recipe.content).to eq('**1 foo Zucker**')

      ingredient = recipe.recipe_ingredients.first
      expect(ingredient.errors[:unit]).to include('foo ist keine erlaubte Einheit')
      expect(recipe.errors[:recipe_ingredients]).to be_present

      # persisted record in DB is unchanged because validation failed
      recipe.reload
      expect(recipe.content).to eq(original_content)
    end
  end
end
