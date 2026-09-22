# frozen_string_literal: true

require 'rails_helper'

# DataTables and its plugins hang off the jQuery instance that webpack's
# ProvidePlugin injects. Bumping either side has silently broken that wiring
# before (see "Fix datatables by pinning jquery to 3.7.1"), and nothing below
# the browser notices, so these examples drive a real client.
RSpec.describe 'DataTables' do
  let(:user) { create(:user, role: :office) }
  let(:group) { create(:group, name: 'Rote Gruppe') }

  before { login_as user, scope: :user }

  # The pages under test hold a single DataTable each.
  def search_box
    find('input[type="search"]')
  end

  def table_rows(table_id)
    all("##{table_id} tbody tr", visible: true)
  end

  # Synchronizes on DataTables having enhanced the table.
  def wait_for_datatable(table_id)
    find("##{table_id}.dataTable")
  end

  def sort_by(table_id, column_title)
    find("##{table_id} thead th", text: column_title).click
  end

  def column_values(table_id, column)
    table_rows(table_id).map { |row| row.all('td')[column].text }
  end

  describe 'initialization' do
    it 'enhances the ingredients table', :demand_cache do
      create(:ingredient, name: 'Zwiebel')

      visit ingredients_path

      expect(page).to have_css('#ingredients-table.dataTable')
    end

    it 'enhances the articles table' do
      create(:article, ingredient: create(:ingredient, name: 'Zwiebel'), unit: 'g', quantity: 500)

      visit articles_path

      expect(page).to have_css('#articles-table.dataTable')
    end

    it 'enhances the participants table' do
      create(:participant, group:)

      visit participants_path

      expect(page).to have_css('#participants-table.dataTable')
    end

    it 'enhances the orders table' do
      create(:order)

      visit orders_path

      expect(page).to have_css('#orders-table.dataTable')
    end

    it 'applies our German defaults instead of paginating', :aggregate_failures do
      create(:participant, group:)

      visit participants_path

      expect(page).to have_css('#participants-table.dataTable')
      expect(page).to have_text('Suche')
      expect(page).to have_no_css('.dt-paging')
    end
  end

  describe 'searching' do
    before do
      create(:participant, group:, comment: 'Kartoffelsalat')
      create(:participant, group: create(:group, name: 'Blaue Gruppe'), comment: 'Kuchen')

      visit participants_path
      wait_for_datatable('participants-table')
    end

    it 'filters the rows down to the matching one', :aggregate_failures do
      search_box.fill_in with: 'Kartoffelsalat'

      expect(page).to have_css('#participants-table tbody tr', count: 1)
      expect(page).to have_text('Kartoffelsalat')
      expect(page).to have_no_text('Kuchen')
    end

    it 'restores all rows when the search is cleared' do
      search_box.fill_in with: 'Kartoffelsalat'
      expect(page).to have_css('#participants-table tbody tr', count: 1)

      search_box.fill_in with: ''

      expect(page).to have_css('#participants-table tbody tr', count: 2)
    end
  end

  describe 'sorting' do
    before do
      create(:participant, group:, age: 45)
      create(:participant, group:, age: 7)
      create(:participant, group:, age: 23)

      visit participants_path
      wait_for_datatable('participants-table')
    end

    it 'sorts a column ascending and descending on click', :aggregate_failures do
      sort_by('participants-table', 'Alter')
      expect(page).to have_css('#participants-table tbody tr:first-child', text: '7')
      expect(column_values('participants-table', 2)).to eq(%w[7 23 45])

      sort_by('participants-table', 'Alter')
      expect(page).to have_css('#participants-table tbody tr:first-child', text: '45')
      expect(column_values('participants-table', 2)).to eq(%w[45 23 7])
    end
  end

  # The FixedColumns plugin is bundled as well, but no table configures it, so
  # the console check in JavascriptErrors is all that guards it.
  describe 'the FixedHeader plugin' do
    before do
      create_list(:participant, 30, group:)

      visit participants_path
      wait_for_datatable('participants-table')
    end

    it 'floats the header once the table scrolls out of view' do
      page.execute_script('window.scrollTo(0, document.body.scrollHeight)')

      expect(page).to have_css('.dtfh-floatingparent thead')
    end
  end

  describe 'turbo navigation' do
    before do
      create(:participant, group:, comment: 'Kartoffelsalat')
      create(:participant, group: create(:group, name: 'Blaue Gruppe'), comment: 'Kuchen')
    end

    it 're-initializes a single working table after going back to a cached page', :aggregate_failures do
      visit participants_path
      expect(page).to have_css('#participants-table.dataTable')

      click_on 'Kochgruppen'
      expect(page).to have_current_path(groups_path)

      page.go_back
      expect(page).to have_css('#participants-table.dataTable')
      expect(page).to have_css('input[type="search"]', count: 1)

      search_box.fill_in with: 'Kuchen'

      expect(page).to have_css('#participants-table tbody tr', count: 1)
    end
  end

  # select2 rides on the same jQuery, so a jQuery bump that breaks it would
  # otherwise only show up in production.
  describe 'select2' do
    it 'replaces the diets select with a select2 widget' do
      create(:diet, name: 'vegan')

      visit new_participant_path

      expect(page).to have_css('.select2-container')
    end
  end
end
