# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Articles' do
  let(:user) { create(:user, role: :office) }

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
end
