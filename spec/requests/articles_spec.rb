# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Articles' do
  let(:user) { create(:user, role: :office) }
  let(:supplier) { create(:supplier) }
  let(:ingredient) { create(:ingredient) }

  before do
    sign_in user, scope: :user
  end

  describe 'GET /articles' do
    before do
      create(:article, price: 2.5, unit: 'g', packing_type: :piece, quantity: 500)
      create(:article, price: nil, unit: 'g', packing_type: :piece, quantity: 500)
    end

    it 'shows article prices', :aggregate_failures do
      get articles_path

      expect(response).to have_http_status(:success)
      expect(response.body).to include('Preis')
      expect(response.body).to include("2,5\u00A0€")
      expect(response.body).not_to include('Grundpreis')
    end

    it 'marks missing prices' do
      get articles_path

      expect(response.body).to include('Fehlt')
    end
  end

  describe 'shared article table' do
    it 'shows price and base price on ingredient pages', :aggregate_failures do
      create(:article, supplier:, ingredient:, price: 2.5, unit: 'g', packing_type: :piece, quantity: 500)

      get ingredient_path(ingredient)

      expect(response).to have_http_status(:success)
      expect(response.body).to include('Preis')
      expect(response.body).to include('Grundpreis')
      expect(response.body).to include("2,5\u00A0€")
    end

    it 'shows missing prices on supplier pages', :aggregate_failures do
      create(:article, supplier:, ingredient:, price: nil, unit: 'g', packing_type: :piece, quantity: 500)

      get supplier_path(supplier)

      expect(response).to have_http_status(:success)
      expect(response.body).to include('Preis')
      expect(response.body).to include('Grundpreis')
      expect(response.body).to include('Fehlt')
    end
  end
end
