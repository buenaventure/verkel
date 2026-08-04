# frozen_string_literal: true

require 'rails_helper'

RSpec.describe OrderSpending do
  let(:supplier) { create(:supplier) }
  let(:article) { create(:article, supplier:, price: 4, unit: 'g', packing_type: :piece, quantity: 1) }
  let(:missing_price_article) do
    create(:article, supplier:, price: nil, unit: 'g', packing_type: :piece, quantity: 1)
  end

  describe '.overview' do
    let(:delivered_day) { Date.new(2026, 8, 1) }
    let(:ordered_day) { Date.new(2026, 8, 3) }
    let(:box) { create(:box, datetime: Date.new(2026, 8, 5).noon) }
    let(:hoard_day) { Date.new(2026, 8, 7) }

    let(:stored_order) do
      create(:order, :stored, supplier:, coverage: delivered_day.all_day)
    end
    let(:ordered_order) do
      create(:order, :ordered, supplier:, coverage: ordered_day.all_day)
    end

    before do
      create(:order_article, order: stored_order, article:, quantity_ordered: 10, quantity_delivered: 8)
      create(:order_article, order: ordered_order, article:, quantity_ordered: 5, quantity_delivered: 0)
      create(:article_box_order_requirement, article:, box:, quantity: 3)
      create(:hoard, article:, until: hoard_day.noon, missing_quantity: 2)
    end

    it 'buckets cost per estimated arrival day', :aggregate_failures do
      overview = described_class.overview

      expect(overview.delivered_by_day[delivered_day]).to eq(32) # 8 * 4
      expect(overview.ordered_by_day[ordered_day]).to eq(20) # 5 * 4
      expect(overview.pending_by_day[box.datetime.to_date]).to eq(12) # 3 * 4
      expect(overview.pending_by_day[hoard_day]).to eq(8) # 2 * 4
      expect(overview.days).to eq([delivered_day, ordered_day, box.datetime.to_date, hoard_day].sort)
    end

    it 'computes final and projected totals', :aggregate_failures do
      overview = described_class.overview

      expect(overview.total_delivered).to eq(32)
      expect(overview.total_ordered).to eq(20)
      expect(overview.total_pending).to eq(20) # 12 + 8
      expect(overview.total_final).to eq(32)
      expect(overview.total_projected).to eq(72)
    end

    context 'with an article missing a price' do
      before do
        create(:order_article, order: stored_order, article: missing_price_article,
                               quantity_ordered: 1, quantity_delivered: 1)
      end

      it 'counts distinct articles missing a price without blowing up the totals' do
        overview = described_class.overview

        expect(overview.missing_price_article_count).to eq(1)
        expect(overview.total_delivered).to eq(32)
      end
    end
  end

  describe '.find' do
    let(:day) { Date.new(2026, 8, 1) }
    let(:order) { create(:order, :stored, supplier:, coverage: day.all_day) }
    let(:box) { create(:box, datetime: day.noon) }

    before do
      create(:order_article, order:, article:, quantity_ordered: 10, quantity_delivered: 4)
      create(:article_box_order_requirement, article:, box:, quantity: 2)
    end

    it 'returns the cost breakdown for a single day', :aggregate_failures do
      spending = described_class.find(day)

      expect(spending.delivered_total).to eq(16) # 4 * 4
      expect(spending.ordered_total).to eq(0)
      expect(spending.pending_total).to eq(8) # 2 * 4
      expect(spending.total).to eq(24)
      expect(spending.delivered_order_articles).to contain_exactly(OrderArticle.last)
      expect(spending.box_requirements).to contain_exactly(ArticleBoxOrderRequirement.last)
    end

    it 'accepts a date string, like a route param' do
      spending = described_class.find(day.iso8601)

      expect(spending.day).to eq(day)
    end

    it 'raises RecordNotFound for an unparseable day, like a bad route param' do
      expect { described_class.find('not-a-date') }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
