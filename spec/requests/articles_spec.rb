# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Articles' do
  let(:user) { create(:user, role: :office) }

  before do
    sign_in user, scope: :user
  end

  describe 'GET /articles' do
    it 'shows article prices and marks missing prices', :aggregate_failures do
      create(:article, price: 2.5)
      create(:article, price: nil)

      get articles_path

      expect(response).to have_http_status(:success)
      expect(response.body).to include('Preis')
      expect(response.body).to include("2,5\u00A0€")
      expect(response.body).to include('Fehlt')
      expect(response.body).not_to include('Grundpreis')
    end
  end
end
