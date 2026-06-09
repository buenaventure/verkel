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
      spending = overview.groups.find { it.id == group.id }

      expect(spending).to be_a(described_class)
      expect(spending.group).to eq(group)
      expect(spending.final_total).to eq(8)
      expect(spending.missing_price_article_count).to eq(1)
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
    it 'wraps the group', :aggregate_failures do
      expect(group.spending).to be_a(described_class)
      expect(group.spending.final_total).to eq(8)
    end
  end

  describe '#spending_timeline' do
    let(:planned_box) { create(:box, datetime: 1.day.from_now) }

    before do
      create(:group_box_article, group:, box: planned_box, article:, quantity: 3)
    end

    it 'returns cumulative costs ordered by box datetime', :aggregate_failures do
      timeline = described_class.find(group.id).spending_timeline

      expect(timeline.length).to eq(2)
      expect(timeline[0][:cumulative_final]).to eq(8.0)
      expect(timeline[0][:cumulative_total]).to eq(8.0)
      expect(timeline[0][:is_final]).to be(true)
      expect(timeline[1][:cumulative_final]).to eq(8.0)
      expect(timeline[1][:cumulative_total]).to eq(20.0)
      expect(timeline[1][:is_final]).to be(false)
    end
  end

  describe '.overview timelines and budgets' do
    let(:planned_box) { create(:box, datetime: 1.day.from_now) }

    before do
      group.update!(budget: 100)
      create(:group_box_article, group:, box: planned_box, article:, quantity: 3)
    end

    it 'returns preloaded overview spendings with timeline and budget', :aggregate_failures do
      spending = described_class.overview.groups.find { it.id == group.id }

      expect(spending.budget).to eq(100)
      expect(spending.spending_timeline.length).to eq(2)
      expect(spending.spending_timeline.last[:cumulative_total]).to eq(20.0)
      expect(spending.over_budget?).to be(false)
    end
  end

  describe 'budget helpers' do
    it 'detects over and near budget', :aggregate_failures do
      group.update!(budget: 8.5)
      spending = described_class.find(group.id)

      expect(spending.over_budget?).to be(false)
      expect(spending.near_budget?).to be(true)

      group.update!(budget: 5)
      spending = described_class.find(group.id)

      expect(spending.over_budget?).to be(true)
      expect(spending.near_budget?).to be(false)
    end
  end
end
