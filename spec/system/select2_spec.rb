# frozen_string_literal: true

require 'rails_helper'

# select2 hangs off the jQuery instance webpack's ProvidePlugin injects, the
# same wiring DataTables depends on, so a jQuery or select2 bump that breaks it
# would otherwise only show up in production.
RSpec.describe 'select2' do
  let(:user) { create(:user, role: :office) }

  before do
    login_as user, scope: :user
    create(:diet, name: 'vegan')
    create(:diet, name: 'glutenfrei')
  end

  it 'replaces the diets select with a select2 widget', :aggregate_failures do
    visit new_participant_path

    expect(page).to have_css('.select2-container')
    expect(page).to have_css('select.select2.select2-hidden-accessible', visible: :all)
  end

  it 'picks a diet through the dropdown', :aggregate_failures do
    visit new_participant_path
    find('.select2-container').click

    expect(page).to have_css('.select2-results__option', text: 'glutenfrei')
    find('.select2-results__option', text: 'vegan').click

    expect(page).to have_css('.select2-selection__choice', text: 'vegan')
    expect(find('select.select2', visible: :all).value).to eq([Diet.find_by(name: 'vegan').id.to_s])
  end
end
