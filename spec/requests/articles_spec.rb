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

    it 'shows the expected surplus next to the current one', :aggregate_failures do
      get articles_path

      expect(response.body).to include('akt. Überschuss')
      expect(response.body).to include('vorauss. Überschuss')
    end
  end

  describe 'GET /articles/:id' do
    it 'shows the expected surplus including deliveries that are not booked in yet', :aggregate_failures do
      article = create(:article, supplier:, ingredient:, unit: 'g', packing_type: :piece, quantity: 500, stock: 10)
      order = create(:order, supplier:, state: :ordered)
      create(:order_article, order:, article:, quantity_ordered: 7, quantity_delivered: 0)

      get article_path(article)

      expect(response).to have_http_status(:success)
      expect(response.body).to include('Aktueller Überschuss')
      expect(response.body).to include('Voraussichtlicher Überschuss')
      # 10 in stock, 7 on their way, nothing reserved for a box yet.
      expect(article.reload).to have_attributes(surplus: 10, expected_surplus: 17)
      expect(response.body).to include('7 unterwegs')
    end
  end

  describe 'shared article table' do
    before { GroupBoxIngredientUnitCache.do_calculate }

    it 'shows price and base price on ingredient pages', :aggregate_failures do
      create(:article, supplier:, ingredient:, price: 2.5, unit: 'g', packing_type: :piece, quantity: 500)

      get ingredient_path(ingredient)

      expect(response.body).to include('Preis')
      expect(response.body).to include('Grundpreis')
      expect(response.body).to include("2,5\u00A0€")
    end

    it 'shows missing prices on supplier pages', :aggregate_failures do
      create(:article, supplier:, ingredient:, price: nil, unit: 'g', packing_type: :piece, quantity: 500)

      get supplier_path(supplier)

      expect(response.body).to include('Preis')
      expect(response.body).to include('Grundpreis')
      expect(response.body).to include('Fehlt')
    end
  end
end
