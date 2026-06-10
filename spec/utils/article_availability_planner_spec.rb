# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ArticleAvailabilityPlanner do
  let(:supplier) { create(:supplier, delivery_time: 24) }
  let(:ingredient) { create(:ingredient) }

  def planner_for(article, box)
    described_class.new(article).tap { |planner| planner.start_processing(box) }
  end

  describe '#reserve' do
    it 'drains stock, then incoming orders, then new orders', :aggregate_failures do
      future_box = create(:box, datetime: 2.days.from_now)
      article = create(:article, :bulk, ingredient:, supplier:, stock: 30, order_limit: nil)
      order = create(
        :order,
        :ordered,
        supplier:,
        coverage: (2.days.ago.beginning_of_day..1.week.from_now.end_of_day)
      )
      create(:order_article, order:, article:, quantity_ordered: 5, quantity_delivered: 0)
      planner = planner_for(article, future_box)

      expect(planner.reserve(10)).to eq(10)
      expect(planner).to have_attributes(stock: 10, ordered: 0, order_requirement: 0)

      expect(planner.reserve(30)).to eq(30)
      expect(planner).to have_attributes(stock: 30, ordered: 5, order_requirement: 5)
    end

    it 'raises when quantity is negative' do
      article = create(:article, :bulk, ingredient:, supplier:, stock: 10)
      planner = planner_for(article, create(:box))

      expect { planner.reserve(-1) }.to raise_error('quantity may not be negative')
    end

    it 'with immediate_only does not place new orders', :aggregate_failures do
      future_box = create(:box, datetime: 2.days.from_now)
      article = create(:article, :bulk, ingredient:, supplier:, stock: 30, order_limit: nil)
      planner = planner_for(article, future_box)

      expect(planner.reserve(50, immediate_only: true)).to eq(30)
      expect(planner).to have_attributes(stock: 30, ordered: 0, order_requirement: 0)
    end

    it 'with orderable_only does not touch stock or incoming orders', :aggregate_failures do
      future_box = create(:box, datetime: 2.days.from_now)
      article = create(:article, :bulk, ingredient:, supplier:, stock: 30, order_limit: 50)
      planner = planner_for(article, future_box)

      expect(planner.reserve(20, orderable_only: true)).to eq(20)
      expect(planner).to have_attributes(stock: 0, ordered: 0, order_requirement: 20)
      expect(planner.immediate_packages).to eq(30)
    end

    it 'respects the article order limit', :aggregate_failures do
      future_box = create(:box, datetime: 2.days.from_now)
      article = create(:article, :bulk, ingredient:, supplier:, stock: 0, order_limit: 15)
      planner = planner_for(article, future_box)

      expect(planner.reserve(25)).to eq(15)
      expect(planner.order_requirement).to eq(15)
      expect(planner.reserve(10)).to eq(0)
    end
  end

  describe '#orderable? and #available?' do
    it 'is not orderable when the box is before the supplier can deliver', :aggregate_failures do
      article = create(:article, :bulk, ingredient:, supplier:, stock: 0, order_limit: 10)
      planner = planner_for(article, create(:box, datetime: Time.zone.now))

      expect(planner).not_to be_orderable
      expect(planner).not_to be_available
    end

    it 'is orderable when the box is after the earliest delivery date', :aggregate_failures do
      article = create(:article, :bulk, ingredient:, supplier:, stock: 0, order_limit: 10)
      planner = planner_for(article, create(:box, datetime: 2.days.from_now))

      expect(planner).to be_orderable
      expect(planner).to be_available
    end
  end

  describe '#total_coverable_units' do
    it 'includes stock and the remaining order limit when orderable' do
      future_box = create(:box, datetime: 2.days.from_now)
      article = create(:article, :bulk, ingredient:, supplier:, stock: 40, order_limit: 25)
      planner = planner_for(article, future_box)

      expect(planner.total_coverable_units).to eq(65)
    end
  end

  describe 'hoards' do
    it 'blocks hoarded stock until the hoard date passes', :aggregate_failures do
      article = create(:article, :bulk, ingredient:, supplier:, stock: 100)
      Hoard.create!(article:, quantity: 40, until: 1.day.from_now)
      soon_box = create(:box, datetime: Time.zone.now)
      later_box = create(:box, datetime: 2.days.from_now)

      expect(planner_for(article, soon_box).immediate_packages).to eq(60)
      expect(planner_for(article.reload, later_box).immediate_packages).to eq(100)
    end
  end

  describe '#order_requirements?' do
    it 'is true when stock, incoming orders, or new orders were reserved' do
      future_box = create(:box, datetime: 2.days.from_now)
      article = create(:article, :bulk, ingredient:, supplier:, stock: 5, order_limit: nil)
      planner = planner_for(article, future_box)

      expect(planner).not_to be_order_requirements
      planner.reserve(8)
      expect(planner).to be_order_requirements
    end
  end
end
