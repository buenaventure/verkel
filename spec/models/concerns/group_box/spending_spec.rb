# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GroupBox::Spending do
  let(:group) { create(:group) }
  let(:box) { create(:box, :packed) }
  let(:group_box) { GroupBox.find_by(group:, box:) }
  let(:article) { create(:article, price: 3, unit: 'g', packing_type: :piece, quantity: 500) }

  before do
    create(:group_box_article, group:, box:, article:, quantity: 2)
  end

  it 'sums article line costs for the group box', :aggregate_failures do
    expect(group_box.group_box_article_costs.count).to eq(1)
    expect(group_box.total_cost).to eq(6)
    expect(group_box.cost_final?).to be(true)
  end
end
