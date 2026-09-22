# frozen_string_literal: true

require 'rails_helper'

# Specs for the two surplus metrics of an article.
#
# #surplus answers "what is left of the goods we physically have, after the
# packing plan took its share". It only becomes correct once the last delivery
# has been booked into the stock (Order#store), because until then the incoming
# goods are missing from `articles.stock` while the plan already covers boxes
# from them via ArticleBoxOrderRequirement#ordered.
#
# #expected_surplus closes that gap: it adds everything that is still on its way
# and subtracts what the plan already reserved from it.
RSpec.describe Article do
  subject(:article) do
    create(:article, supplier:, unit: 'g', packing_type: :piece, quantity: 500, stock: 10)
  end

  let(:supplier) { create(:supplier) }
  let(:box) { create(:box) }

  # An order for this article in a given state. `delivered` defaults to the
  # ordered amount, mirroring what Order#deliver does.
  def open_order(state, quantity_ordered: 7, quantity_delivered: quantity_ordered)
    order = create(:order, supplier:, state:)
    create(:order_article, order:, article:, quantity_ordered:, quantity_delivered:)
    order
  end

  describe '#surplus' do
    it 'is the plain stock when nothing is planned or picked' do
      expect(article.surplus).to eq(10)
    end

    it 'adds the stock sitting on a packing lane for a picked box' do
      create(:packing_lane_article_stock, article:, box: create(:box, :picked), quantity: 3)

      expect(article.surplus).to eq(13)
    end

    it 'ignores packing lane stock of a box that is not being picked' do
      create(:packing_lane_article_stock, article:, box: create(:box), quantity: 3)

      expect(article.surplus).to eq(10)
    end

    it 'subtracts the stock the packing plan reserved for a box' do
      create(:article_box_order_requirement, article:, box:, quantity: 0, stock: 4, ordered: 0)

      expect(article.surplus).to eq(6)
    end
  end

  describe '#quantity_incoming' do
    it 'counts the ordered quantity of an ordered order' do
      open_order(:ordered, quantity_ordered: 7, quantity_delivered: 0)

      expect(article.quantity_incoming).to eq(7)
    end

    it 'counts the delivered quantity of a delivered order' do
      open_order(:delivered, quantity_ordered: 7, quantity_delivered: 5)

      expect(article.quantity_incoming).to eq(5)
    end

    it 'ignores a stored order because it is already part of the stock' do
      open_order(:stored)

      expect(article.quantity_incoming).to eq(0)
    end

    it 'ignores a planned order' do
      open_order(:planned)

      expect(article.quantity_incoming).to eq(0)
    end

    it 'ignores a canceled order' do
      open_order(:canceled)

      expect(article.quantity_incoming).to eq(0)
    end

    it 'sums up several open orders' do
      open_order(:ordered, quantity_ordered: 7, quantity_delivered: 0)
      open_order(:delivered, quantity_ordered: 4, quantity_delivered: 4)

      expect(article.quantity_incoming).to eq(11)
    end
  end

  describe '#expected_surplus' do
    it 'equals the surplus when nothing is on its way' do
      expect(article.expected_surplus).to eq(article.surplus)
    end

    it 'adds a delivery that no planned box needs' do
      open_order(:ordered, quantity_ordered: 7, quantity_delivered: 0)

      expect(article.expected_surplus).to eq(17)
    end

    it 'does not count a delivery the packing plan already reserved in full' do
      open_order(:ordered, quantity_ordered: 7, quantity_delivered: 0)
      create(:article_box_order_requirement, article:, box:, quantity: 0, stock: 0, ordered: 7)

      expect(article.expected_surplus).to eq(10)
    end

    it 'counts only the part of a delivery the packing plan does not need' do
      open_order(:ordered, quantity_ordered: 7, quantity_delivered: 0)
      create(:article_box_order_requirement, article:, box:, quantity: 0, stock: 0, ordered: 4)

      expect(article.expected_surplus).to eq(13)
    end

    it 'is not inflated by a canceled order' do
      open_order(:canceled)

      expect(article.expected_surplus).to eq(article.surplus)
    end

    it 'is never smaller than the surplus' do
      open_order(:ordered, quantity_ordered: 7, quantity_delivered: 0)
      create(:packing_lane_article_stock, article:, box: create(:box, :picked), quantity: 3)
      create(:article_box_order_requirement, article:, box:, quantity: 2, stock: 4, ordered: 6)

      expect(article.expected_surplus).to be >= article.surplus
    end

    # The point of the whole metric: booking a delivery in must not move the
    # forecast, it only makes #surplus climb towards it. ArticleBoxOrderRequirement
    # rows are untouched by Order#store (only an explicit ArticlePackingPlanner
    # run rewrites them), so this is exactly what a user sees before and after
    # pressing "einlagern".
    it 'does not change when a delivery is booked into the stock', :aggregate_failures do
      order = open_order(:delivered, quantity_ordered: 7, quantity_delivered: 7)
      create(:article_box_order_requirement, article:, box:, quantity: 0, stock: 0, ordered: 4)

      expect(article.expected_surplus).to eq(13)
      expect(article.surplus).to eq(10)

      expect { order.store(create(:user)) }.not_to(change { article.reload.expected_surplus })
      # The 4 reserved from the delivery stay reserved until the planner runs
      # again and moves them from `ordered` to `stock`.
      expect(article.reload.surplus).to eq(17)
    end

    it 'is what the surplus becomes once the last delivery is booked in', :aggregate_failures do
      order = open_order(:delivered, quantity_ordered: 7, quantity_delivered: 7)

      expect(article.surplus).to eq(10)
      expect(article.expected_surplus).to eq(17)

      order.store(create(:user))

      expect(article.reload.surplus).to eq(17)
      expect(article.expected_surplus).to eq(17)
    end
  end

  describe '#quantity_unit_expected_surplus' do
    it 'scales the expected surplus with the package size' do
      open_order(:ordered, quantity_ordered: 7, quantity_delivered: 0)

      expect(article.quantity_unit_expected_surplus).to have_attributes(quantity: 8500, unit: 'g')
    end
  end
end
