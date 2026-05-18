# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'PackingLaneBoxes' do
  let(:user) { create(:user, role: :laga) }
  let(:packing_lane) { create(:packing_lane) }
  let(:box) { create(:box, :picked) }
  let(:packing_lane_box) { PackingLaneBox.new(packing_lane:, box:) }
  let!(:stocks) do
    [
      PackingLaneArticleStock.create!(
        packing_lane:, box:, article: create(:article, unit: 'g', packing_type: :piece, quantity: 500), quantity: 3
      ),
      PackingLaneArticleStock.create!(
        packing_lane:, box:, article: create(:article, unit: 'g', packing_type: :piece, quantity: 500), quantity: 7
      )
    ]
  end

  before do
    sign_in user, scope: :user
  end

  describe 'PATCH /packing_lane_boxes/:id' do
    it 'updates all changed stock quantities' do
      patch packing_lane_box_path(packing_lane_box), params: stock_quantity_params(13, 17)
      expect(stocks.map { |stock| stock.reload.quantity }).to eq([13, 17])
    end

    it 'redirects to the packing lane box' do
      patch packing_lane_box_path(packing_lane_box), params: stock_quantity_params(13, 17)
      expect(response).to redirect_to(packing_lane_box_path(packing_lane_box))
    end
  end

  def stock_quantity_params(first_quantity, second_quantity)
    {
      packing_lane_box: {
        packing_lane_article_stocks_attributes: {
          '0' => { id: stocks[0].id, quantity: first_quantity },
          '1' => { id: stocks[1].id, quantity: second_quantity }
        }
      }
    }
  end
end
