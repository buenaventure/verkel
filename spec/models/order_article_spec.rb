# frozen_string_literal: true

require 'rails_helper'

RSpec.describe OrderArticle do
  # #quantity_incoming is the single definition of "this is still on its way
  # and not yet part of article.stock". Both ArticleAvailabilityPlanner and
  # Article#quantity_incoming rely on it, so every order state is pinned here.
  describe '#quantity_incoming' do
    subject(:order_article) do
      create(:order_article, order:, article:, quantity_ordered: 7, quantity_delivered: 5)
    end

    let(:supplier) { create(:supplier) }
    let(:article) { create(:article, supplier:, unit: 'g', packing_type: :piece, quantity: 500) }
    let(:order) { create(:order, supplier:, state:) }

    context 'when the order is ordered' do
      let(:state) { :ordered }

      it 'expects the ordered quantity to arrive' do
        expect(order_article.quantity_incoming).to eq(7)
      end
    end

    context 'when the order is delivered' do
      let(:state) { :delivered }

      # What actually arrived can differ from what was ordered, and only the
      # delivered amount will ever be booked into the stock.
      it 'counts the delivered quantity, not the ordered one' do
        expect(order_article.quantity_incoming).to eq(5)
      end
    end

    context 'when the order is stored' do
      let(:state) { :stored }

      it 'counts nothing because the goods are already in the stock' do
        expect(order_article.quantity_incoming).to eq(0)
      end
    end

    context 'when the order is still planned' do
      let(:state) { :planned }

      it 'counts nothing because it has not been ordered yet' do
        expect(order_article.quantity_incoming).to eq(0)
      end
    end

    context 'when the order is canceled' do
      let(:state) { :canceled }

      it 'counts nothing because it will never arrive' do
        expect(order_article.quantity_incoming).to eq(0)
      end
    end
  end
end
