# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GroupBoxCost do
  let(:group) { create(:group) }
  let(:article) { create(:article, price: 4, unit: 'g', packing_type: :piece, quantity: 500) }
  let(:packed_box) { create(:box, :packed) }
  let(:planned_box) { create(:box) }
  let(:missing_price_article) { create(:article, price: nil, unit: 'g', packing_type: :piece, quantity: 500) }

  before do
    create(:group_box_article, group:, box: packed_box, article:, quantity: 2)
    create(:group_box_article, group:, box: planned_box, article:, quantity: 1)
    create(:group_box_article,
           group:,
           box: planned_box,
           article: create(:article, price: 3, unit: 'g', packing_type: :piece, quantity: 500),
           quantity: 0)
    create(:group_box_article, group:, box: planned_box, article: missing_price_article, quantity: 1)
  end

  it 'calculates line totals from current article prices', :aggregate_failures do
    article_cost = GroupBoxArticleCost.find_by(group:, box: packed_box, article:)

    expect(article_cost.line_total).to eq(8)
    expect(article_cost.is_final).to be(true)
  end

  it 'aggregates final totals per group and box', :aggregate_failures do
    packed_cost = described_class.find_by(group:, box: packed_box)

    expect(packed_cost.total_cost).to eq(8)
    expect(packed_cost.is_final).to be(true)
  end

  it 'aggregates planned totals per group and box', :aggregate_failures do
    planned_cost = described_class.find_by(group:, box: planned_box)

    expect(planned_cost.total_cost).to eq(4)
    expect(planned_cost.is_final).to be(false)
  end

  it 'excludes zero-quantity rows' do
    expect(GroupBoxArticleCost.pluck(:quantity)).not_to include(0)
  end

  it 'exposes rows with missing article prices', :aggregate_failures do
    article_cost = GroupBoxArticleCost.find_by(group:, box: planned_box, article: missing_price_article)

    expect(article_cost).to be_missing_price
    expect(article_cost.line_total).to be_nil
    expect(GroupBoxArticleCost.missing_price).to contain_exactly(article_cost)
  end
end
