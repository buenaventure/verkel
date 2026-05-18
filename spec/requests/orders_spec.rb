# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Orders' do
  let(:user) { create(:user, role: :office) }
  let(:supplier) { create(:supplier) }
  let(:order) { create(:order, supplier:) }

  def order_article_quantity_params(articles_with_quantities)
    {
      order: {
        order_articles_attributes: articles_with_quantities.each_with_index.to_h do |(article, quantity), index|
          [index.to_s, { id: article.id, quantity_ordered: quantity }]
        end
      }
    }
  end

  def invalid_order_article_quantity_params(article, quantity)
    order_article_quantity_params([[article, quantity]])
  end

  before do
    sign_in user, scope: :user
  end

  describe 'GET /orders' do
    it 'returns a successful response' do
      get orders_path
      expect(response).to have_http_status(:success)
    end
  end

  describe 'GET /orders/:id' do
    it 'returns a successful response' do
      get order_path(order)
      expect(response).to have_http_status(:success)
    end

    it 'returns PDF format', :aggregate_failures do
      get order_path(order, format: :pdf)
      expect(response).to have_http_status(:success)
      expect(response.content_type).to include('application/pdf')
    end
  end

  describe 'GET /orders/new' do
    it 'returns a successful response' do
      get new_order_path
      expect(response).to have_http_status(:success)
    end

    it 'preselects the supplier when supplier_id is given' do
      get new_order_path, params: { supplier_id: supplier.id }
      expect(response).to have_http_status(:success)
    end
  end

  describe 'GET /orders/:id/edit' do
    it 'returns a successful response' do
      get edit_order_path(order)
      expect(response).to have_http_status(:success)
    end
  end

  describe 'GET /orders/:id/edit_quantities' do
    let(:order) { create(:order, :ordered, supplier:) }

    before do
      create(:order_article, order:, quantity_ordered: 5)
    end

    it 'returns a successful response' do
      get edit_quantities_order_path(order)
      expect(response).to have_http_status(:success)
    end
  end

  describe 'POST /orders' do
    context 'with valid parameters' do
      let(:valid_attributes) do
        coverage_begin = 1.week.from_now.beginning_of_day
        coverage_end = 2.weeks.from_now.end_of_day

        {
          order: {
            supplier_id: supplier.id,
            coverage_begin: multiparameter_attributes(coverage_begin),
            coverage_end: multiparameter_attributes(coverage_end)
          }
        }
      end

      it 'creates a new order' do
        expect do
          post orders_path, params: valid_attributes
        end.to change(Order, :count).by(1)
      end

      it 'redirects to the created order' do
        post orders_path, params: valid_attributes
        expect(response).to redirect_to(order_path(Order.last))
      end

      it 'sets a success notice' do
        post orders_path, params: valid_attributes
        follow_redirect!
        expect(response.body).to include('erfolgreich erstellt')
      end
    end

    context 'with invalid parameters' do
      let(:invalid_attributes) do
        coverage_begin = 1.week.from_now.beginning_of_day
        coverage_end = 2.weeks.from_now.end_of_day

        {
          order: {
            supplier_id: supplier.id,
            coverage_begin: multiparameter_attributes(coverage_end),
            coverage_end: multiparameter_attributes(coverage_begin)
          }
        }
      end

      it 'does not create a new order' do
        expect do
          post orders_path, params: invalid_attributes
        end.not_to change(Order, :count)
      end

      it 'returns unprocessable_entity status' do
        post orders_path, params: invalid_attributes
        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  describe 'PATCH /orders/:id' do
    context 'with valid order attributes' do
      let(:new_attributes) do
        new_coverage_begin = 2.weeks.from_now.beginning_of_day
        new_coverage_end = 3.weeks.from_now.end_of_day

        {
          order: {
            supplier_id: supplier.id,
            coverage_begin: multiparameter_attributes(new_coverage_begin),
            coverage_end: multiparameter_attributes(new_coverage_end)
          }
        }
      end

      it 'updates the coverage begin' do
        patch order_path(order), params: new_attributes
        expect(order.reload.coverage_begin).to eq(2.weeks.from_now.beginning_of_day)
      end

      it 'updates the coverage end' do
        patch order_path(order), params: new_attributes
        expect(order.reload.coverage_end.change(sec: 0)).to eq(3.weeks.from_now.end_of_day.change(sec: 0))
      end

      it 'redirects to the order' do
        patch order_path(order), params: new_attributes
        expect(response).to redirect_to(order_path(order))
      end
    end

    context 'with invalid order attributes' do
      let(:invalid_attributes) do
        {
          order: {
            supplier_id: supplier.id,
            coverage_begin: multiparameter_attributes(order.coverage_end),
            coverage_end: multiparameter_attributes(order.coverage_begin)
          }
        }
      end

      it 'does not update the order' do
        original_coverage_begin = order.coverage_begin
        patch order_path(order), params: invalid_attributes
        order.reload
        expect(order.coverage_begin).to eq(original_coverage_begin)
      end

      it 'returns unprocessable_entity status' do
        patch order_path(order), params: invalid_attributes
        expect(response).to have_http_status(:unprocessable_content)
      end

      it 'renders the edit template' do
        patch order_path(order), params: invalid_attributes
        expect(response.body).to include('Bestellung bearbeiten')
      end
    end

    context 'when updating quantities from edit_quantities' do
      let(:order) { create(:order, :ordered, supplier:) }
      let(:order_articles) do
        [
          create(:order_article, order:, quantity_ordered: 5),
          create(:order_article, order:, quantity_ordered: 8)
        ]
      end
      let(:updated_quantities) { [[order_articles[0], 12], [order_articles[1], 20]] }

      before { order_articles }

      it 'updates all changed order article quantities', :aggregate_failures do
        patch order_path(order), params: order_article_quantity_params(updated_quantities)
        expect(order_articles[0].reload.quantity_ordered).to eq(12)
        expect(order_articles[1].reload.quantity_ordered).to eq(20)
      end

      it 'redirects to the order' do
        patch order_path(order), params: order_article_quantity_params(updated_quantities)
        expect(response).to redirect_to(order_path(order))
      end

      it 'does not update the order article with invalid quantities' do
        patch order_path(order), params: invalid_order_article_quantity_params(order_articles[0], -1)
        expect(order_articles[0].reload.quantity_ordered).to eq(5)
      end

      it 'returns unprocessable_entity status for invalid quantities' do
        patch order_path(order), params: invalid_order_article_quantity_params(order_articles[0], -1)
        expect(response).to have_http_status(:unprocessable_content)
      end

      it 'renders the edit_quantities template for invalid quantities' do
        patch order_path(order), params: invalid_order_article_quantity_params(order_articles[0], -1)
        expect(response.body).to include('Mengen bearbeiten')
      end
    end

    context 'when a laga user updates delivered quantities' do
      let(:user) { create(:user, role: :laga) }
      let(:order) { create(:order, :delivered, supplier:) }
      let!(:order_article) { create(:order_article, order:, quantity_ordered: 5, quantity_delivered: 5) }
      let(:quantity_attributes) do
        {
          order: {
            order_articles_attributes: {
              '0' => { id: order_article.id, quantity_delivered: 7 }
            }
          }
        }
      end

      it 'updates the delivered quantity' do
        patch order_path(order), params: quantity_attributes
        expect(order_article.reload.quantity_delivered).to eq(7)
      end

      it 'redirects to the order' do
        patch order_path(order), params: quantity_attributes
        expect(response).to redirect_to(order_path(order))
      end
    end
  end

  describe 'DELETE /orders/:id' do
    context 'when order can be destroyed' do
      it 'destroys the requested order' do
        order_to_delete = create(:order, supplier:)
        expect do
          delete order_path(order_to_delete)
        end.to change(Order, :count).by(-1)
      end

      it 'redirects to the orders list' do
        order_to_delete = create(:order, supplier:)
        delete order_path(order_to_delete)
        expect(response).to redirect_to(orders_path)
      end

      it 'sets a success notice' do
        order_to_delete = create(:order, supplier:)
        delete order_path(order_to_delete)
        follow_redirect!
        expect(response.body).to include('erfolgreich gelöscht')
      end
    end

    context 'when order cannot be destroyed' do
      it 'handles destroy failure gracefully' do
        order_to_delete = create(:order, supplier:)
        allow(order_to_delete).to receive(:destroy).and_return(false)
        allow(Order).to receive(:find).and_return(order_to_delete)

        delete order_path(order_to_delete)
        expect(response).to redirect_to(order_path(order_to_delete))
      end
    end
  end

  describe 'POST /orders/:id/order' do
    let(:order) { create(:order, supplier:) }

    it 'marks the order as ordered' do
      post order_order_path(order)
      expect(order.reload).to be_ordered
    end

    it 'redirects to the order with a notice' do
      post order_order_path(order)
      follow_redirect!
      expect(response.body).to include('erfolgreich als bestellt eingetragen')
    end

    context 'when the order cannot be placed' do
      let(:order) { create(:order, :ordered, supplier:) }

      it 'redirects to the order with an alert' do
        post order_order_path(order)
        follow_redirect!
        expect(response.body).to include('konnte nicht als bestellt eingetragen werden')
      end
    end
  end

  describe 'POST /orders/:id/deliver' do
    let(:order) { create(:order, :ordered, supplier:) }
    let!(:order_article) { create(:order_article, order:, quantity_ordered: 6, quantity_delivered: 0) }

    it 'marks the order as delivered' do
      post deliver_order_path(order)
      expect(order.reload).to be_delivered
    end

    it 'copies ordered quantities to delivered quantities' do
      post deliver_order_path(order)
      expect(order_article.reload.quantity_delivered).to eq(6)
    end

    it 'redirects to the order with a notice' do
      post deliver_order_path(order)
      follow_redirect!
      expect(response.body).to include('erfolgreich als geliefert eingetragen')
    end

    context 'when the order cannot be delivered' do
      let(:order) { create(:order, supplier:) }

      it 'redirects to the order with an alert' do
        post deliver_order_path(order)
        follow_redirect!
        expect(response.body).to include('konnte nicht als geliefert eingetragen werden')
      end
    end
  end

  describe 'POST /orders/:id/store' do
    let(:user) { create(:user, role: :laga) }
    let(:order) { create(:order, :delivered, supplier:) }
    let(:article) { create(:article, supplier:, stock: 3, unit: 'g', packing_type: :piece, quantity: 500) }
    let(:order_article) do
      create(:order_article, order:, article:, quantity_ordered: 6, quantity_delivered: 4)
    end

    before { order_article }

    it 'marks the order as stored' do
      post store_order_path(order)
      expect(order.reload).to be_stored
    end

    it 'adds delivered quantities to article stock' do
      post store_order_path(order)
      expect(article.reload.stock).to eq(7)
    end

    it 'redirects to the order with a notice' do
      post store_order_path(order)
      follow_redirect!
      expect(response.body).to include('erfolgreich als eingelagert eingetragen')
    end

    context 'when the order cannot be stored' do
      let(:order) { create(:order, :ordered, supplier:) }

      it 'redirects to the order with an alert' do
        post store_order_path(order)
        follow_redirect!
        expect(response.body).to include('konnte nicht als eingelagert eingetragen werden')
      end
    end
  end

  describe 'POST /orders/:id/cancel' do
    let(:order) { create(:order, supplier:) }

    it 'marks the order as canceled' do
      post cancel_order_path(order)
      expect(order.reload).to be_canceled
    end

    it 'redirects to the order with a notice' do
      post cancel_order_path(order)
      follow_redirect!
      expect(response.body).to include('erfolgreich als abgebrochen eingetragen')
    end

    context 'when the order cannot be canceled' do
      let(:order) { create(:order, :delivered, supplier:) }

      it 'redirects to the order with an alert' do
        post cancel_order_path(order)
        follow_redirect!
        expect(response.body).to include('konnte nicht als abgebrochen eingetragen werden')
      end
    end
  end
end
