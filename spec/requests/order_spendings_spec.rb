# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Order spendings' do
  let(:supplier) { create(:supplier) }
  let(:article) { create(:article, supplier:, price: 4, unit: 'g', packing_type: :piece, quantity: 1) }
  let(:day) { Date.new(2026, 8, 1) }
  let(:order) { create(:order, :stored, supplier:, coverage: day.all_day) }

  before do
    create(:order_article, order:, article:, quantity_ordered: 10, quantity_delivered: 4)
  end

  describe 'GET /order_spendings' do
    context 'when signed in as office user' do
      before { sign_in create(:user, role: :office), scope: :user }

      it 'returns a successful response' do
        get order_spendings_path
        expect(response).to have_http_status(:success)
      end

      it 'shows cost totals and the cross-linked comparison panel', :aggregate_failures do
        get order_spendings_path

        expect(response.body).to include('Kostenübersicht (Bestellungen)')
        expect(response.body).to include('16,0 €')
        expect(response.body).to include('Kostenvergleich')
        expect(response.body).to include(group_spendings_path)
      end

      it 'highlights the delta when incoming cost exceeds outgoing spending', :aggregate_failures do
        # no GroupSpending data exists in this spec, so outgoing spending is 0 and the
        # full incoming total (16,0 €) shows up as a positive, highlighted delta
        get order_spendings_path

        expect(response.body).to include('text-danger fw-semibold')
        expect(response.body.scan('16,0 €').size).to be >= 3 # delivered column, final delta, projected delta
      end
    end

    context 'when signed in as read-only user' do
      before { sign_in create(:user, role: :read_only), scope: :user }

      it 'denies access' do
        get order_spendings_path
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe 'GET /order_spendings/:day' do
    context 'when signed in as office user' do
      before { sign_in create(:user, role: :office), scope: :user }

      it 'shows the breakdown for that day', :aggregate_failures do
        get order_spending_path(day)

        expect(response).to have_http_status(:success)
        expect(response.body).to include('Geliefert / eingelagert')
        expect(response.body).to include('16,0 €')
      end

      it 'returns 404 for an unparseable day' do
        get '/order_spendings/not-a-date'
        expect(response).to have_http_status(:not_found)
      end
    end

    context 'when signed in as read-only user' do
      before { sign_in create(:user, role: :read_only), scope: :user }

      it 'denies access' do
        get order_spending_path(day)
        expect(response).to redirect_to(root_path)
      end
    end
  end
end
