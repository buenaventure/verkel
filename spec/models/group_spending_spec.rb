# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GroupSpending do
  let(:group) { create(:group) }
  let(:article) { create(:article, price: 4, unit: 'g', packing_type: :piece, quantity: 500) }
  let(:missing_price_article) { create(:article, price: nil, unit: 'g', packing_type: :piece, quantity: 500) }
  let(:packed_box) { create(:box, :packed) }

  before do
    create(:group_box_article, group:, box: packed_box, article:, quantity: 2)
    create(:group_box_article, group:, box: packed_box, article: missing_price_article, quantity: 1)
  end

  describe '.overview' do
    it 'returns an overview with groups and cost totals', :aggregate_failures do
      overview = described_class.overview

      expect(overview).to be_a(described_class::Overview)
      expect(overview.groups).to include(group)
      expect(overview.final_totals_by_group[group.id]).to eq(8)
      expect(overview.missing_price_article_counts_by_group[group.id]).to eq(1)
    end
  end

  describe '.find' do
    it 'returns spending for one group', :aggregate_failures do
      spending = described_class.find(group.id)

      expect(spending.group).to eq(group)
      expect(spending.final_total).to eq(8)
      expect(spending.costs_by_box.keys).to eq([packed_box])
      expect(spending.missing_price_article_count).to eq(1)
    end
  end

  describe '#spending on Group' do
    it 'wraps the group' do
      expect(group.spending).to be_a(described_class)
      expect(group.spending.final_total).to eq(8)
    end
  end
end
