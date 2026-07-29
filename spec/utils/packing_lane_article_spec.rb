# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PackingLaneArticle do
  describe '#humanize_quantity' do
    def build_packing_lane_article(article:, quantity_required:, stock: nil)
      described_class.new(article:, quantity_required:, stock:, packing_lane: nil, box: nil)
    end

    it 'formats piece quantities as a plain number' do
      article = build_stubbed(:article, :piece)
      packing_lane_article = build_packing_lane_article(article:, quantity_required: 3)

      expect(packing_lane_article.humanize_quantity(:required)).to eq '3'
    end

    it 'formats bulk quantities using the article unit' do
      article = build_stubbed(:article, :bulk, quantity: 1, unit: 'g')
      packing_lane_article = build_packing_lane_article(article:, quantity_required: 1500)

      expect(packing_lane_article.humanize_quantity(:required)).to include 'kg'
    end

    it 'derives available quantity from stock' do
      stock = build_stubbed(:packing_lane_article_stock, quantity: 5)
      article = build_stubbed(:article, :piece)
      packing_lane_article = build_packing_lane_article(article:, quantity_required: 0, stock:)

      expect(packing_lane_article.humanize_quantity(:available)).to eq '5'
    end

    it 'derives difference as required minus available' do
      stock = build_stubbed(:packing_lane_article_stock, quantity: 2)
      article = build_stubbed(:article, :piece)
      packing_lane_article = build_packing_lane_article(article:, quantity_required: 5, stock:)

      expect(packing_lane_article.humanize_quantity(:difference)).to eq '3'
    end

    it 'raises for an unknown kind' do
      article = build_stubbed(:article, :piece)
      packing_lane_article = build_packing_lane_article(article:, quantity_required: 1)

      expect { packing_lane_article.humanize_quantity(:bogus) }.to raise_error(ArgumentError)
    end
  end
end
