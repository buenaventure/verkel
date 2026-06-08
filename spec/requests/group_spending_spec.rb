# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Group spendings' do
  let(:group) { create(:group) }
  let(:article) { create(:article, price: 1250.5, unit: 'g', packing_type: :piece, quantity: 500) }
  let(:missing_price_article) { create(:article, price: nil, unit: 'g', packing_type: :piece, quantity: 500) }
  let(:packed_box) { create(:box, :packed, datetime: 1.day.ago) }
  let(:planned_box) { create(:box, datetime: 1.day.from_now) }

  before do
    create(:group_box_article, group:, box: packed_box, article:, quantity: 2)
    create(:group_box_article, group:, box: planned_box, article:, quantity: 3)
    create(:group_box_article, group:, box: planned_box, article: missing_price_article, quantity: 1)
  end

  describe 'GET /group_spendings' do
    context 'when signed in as office user' do
      before { sign_in create(:user, role: :office), scope: :user }

      it 'returns a successful response' do
        get group_spendings_path
        expect(response).to have_http_status(:success)
      end

      it 'shows cost totals in the overview', :aggregate_failures do
        get group_spendings_path

        expect(response.body).to include('Kostenübersicht')
        expect(response.body).to include("2.501,0\u00A0€")
        expect(response.body).to include("3.751,5\u00A0€")
        expect(response.body).to include('1 ohne Preis')
      end
    end

    context 'when signed in as read-only user' do
      before { sign_in create(:user, role: :read_only), scope: :user }

      it 'denies access' do
        get group_spendings_path
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe 'GET /group_spendings/:group_id' do
    context 'when signed in as office user' do
      before { sign_in create(:user, role: :office), scope: :user }

      it 'returns a successful response' do
        get group_spending_path(group)
        expect(response).to have_http_status(:success)
      end

      it 'shows grouped line items and totals', :aggregate_failures do
        get group_spending_path(group)

        expect(response.body).to include(group.display_name)
        expect(response.body).to include('Summe endgültig')
        expect(response.body).to include("2 501,0\u00A0€")
        expect(response.body).to include("6 252,5\u00A0€")
      end

      it 'shows and highlights missing-price articles', :aggregate_failures do
        get group_spending_path(group)

        expect(response.body).to include('Preis fehlt:')
        expect(response.body).to include(missing_price_article.packing_name)
        expect(response.body).to include('table-danger')
      end
    end
  end
end
