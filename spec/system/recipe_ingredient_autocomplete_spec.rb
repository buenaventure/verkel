# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Recipe ingredient autocomplete' do
  let(:user) { create(:user, role: :office) }
  let(:suggestions) { find('.recipe-ingredient-suggestions', visible: :all) }

  before do
    login_as user, scope: :user
    Unit.create!(name: 'Stk')
    create(:ingredient, name: 'Mehl')
    create(:ingredient, name: 'Weizenmehl')
    create(:ingredient, name: 'Mandeln')
    create(:diet, name: 'vegan')
    visit new_recipe_path
  end

  def content
    find_field('Rezept')
  end

  it 'completes the unit', :aggregate_failures do
    content.send_keys('Erst **500 k')
    expect(suggestions).to have_css('.dropdown-item.active', text: 'kg')
    content.send_keys(:enter)
    expect(content.value).to eq('Erst **500 kg ')
  end

  it 'completes the ingredient name and closes the ingredient', :aggregate_failures do
    content.send_keys('Erst **500 kg mehl')
    expect(suggestions).to have_css('.dropdown-item.active', text: 'Mehl')
    content.send_keys(:down, :enter)
    expect(content.value).to eq('Erst **500 kg Weizenmehl**')
    expect(page).to have_no_css('.recipe-ingredient-suggestions.show')
  end

  it 'suggests diets inside the parentheses', :aggregate_failures do
    content.send_keys('**5 g Mandeln (+ve')
    expect(suggestions).to have_css('.dropdown-item', text: '+vegan')
    content.send_keys(:tab)
    expect(content.value).to eq('**5 g Mandeln (+vegan')
  end

  it 'warns about disallowed units and new ingredients', :aggregate_failures do
    content.send_keys('**3 Prise Salz')
    expect(suggestions).to have_text('„Prise“ ist keine erlaubte Einheit')
    expect(suggestions).to have_text('„Salz“ wird als neue Zutat angelegt')
  end

  it 'warns about a diet without sign' do
    content.send_keys('**5 g Mandeln (laktosefrei')
    expect(suggestions).to have_text('„laktosefrei“ mit + (geeignet) oder - (ungeeignet) kennzeichnen')
  end

  it 'warns about an ingredient without quantity' do
    content.send_keys('**Salz')
    expect(suggestions).to have_text('Zutaten beginnen mit Menge und Einheit')
  end

  it 'stays closed outside of bold text' do
    content.send_keys('500 g Mehl')
    expect(page).to have_no_css('.recipe-ingredient-suggestions.show')
  end

  it 'stays closed after Escape while typing the same ingredient', :aggregate_failures do
    content.send_keys('**5 g Me')
    expect(page).to have_css('.recipe-ingredient-suggestions.show')
    content.send_keys(:escape, 'h')
    expect(page).to have_no_css('.recipe-ingredient-suggestions.show')
  end
end
