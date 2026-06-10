# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ArticlePiecePackageSelector do
  let(:supplier) { create(:supplier, delivery_time: 24) }
  let(:ingredient) { create(:ingredient) }
  let(:box) { create(:box) }

  before { Unit.create!(name: 'Stk') }

  def planners_for(*articles)
    articles.map do |article|
      ArticleAvailabilityPlanner.new(article).tap { it.start_processing(box) }
    end
  end

  def select(required_units, *articles, **options)
    described_class.new(required_units, planners_for(*articles), **options).select
  end

  describe '#select' do
    it 'returns an empty hash when nothing is required' do
      article = create(:article, ingredient:, supplier:, packing_type: :piece, unit: 'Stk', quantity: 10, stock: 5)

      expect(select(0, article)).to eq({})
    end

    it 'returns an empty hash when no article is available' do
      article = create(:article, ingredient:, supplier:, packing_type: :piece, unit: 'Stk', quantity: 10, stock: 0)

      expect(select(20, article)).to eq({})
    end

    it 'minimises package count over overshoot (32 Stk -> 2x20)', :aggregate_failures do
      pack20 = create(:article, ingredient:, supplier:, packing_type: :piece, unit: 'Stk', quantity: 20, stock: 10)
      pack10 = create(:article, ingredient:, supplier:, packing_type: :piece, unit: 'Stk', quantity: 10, stock: 10, priority: 1)

      combination = select(32, pack20, pack10)

      expect(combination).to eq(pack20.id => 2)
    end

    it 'minimises overshoot after package count (120 Stk -> 1x100 + 1x30)', :aggregate_failures do
      big = create(:article, ingredient:, supplier:, packing_type: :piece, unit: 'Stk', quantity: 100, stock: 10)
      small = create(:article, ingredient:, supplier:, packing_type: :piece, unit: 'Stk', quantity: 30, stock: 10)

      combination = select(120, big, small)

      expect(combination).to eq(big.id => 1, small.id => 1)
    end

    it 'prefers lower-priority articles when package count and overshoot tie', :aggregate_failures do
      preferred = create(:article, ingredient:, supplier:, packing_type: :piece, unit: 'Stk', quantity: 20, stock: 5, priority: 0)
      alternate = create(:article, ingredient:, supplier:, packing_type: :piece, unit: 'Stk', quantity: 20, stock: 5, priority: 5)

      combination = select(20, alternate, preferred)

      expect(combination).to eq(preferred.id => 1)
    end

    it 'returns the best partial combination when demand exceeds available stock', :aggregate_failures do
      article = create(:article, ingredient:, supplier:, packing_type: :piece, unit: 'Stk', quantity: 16, stock: 1)

      expect(select(32, article)).to eq(article.id => 1)
    end

    it 'with only: :immediate considers only stock and incoming orders', :aggregate_failures do
      future_box = create(:box, datetime: 2.days.from_now)
      article = create(:article, ingredient:, supplier:, packing_type: :piece, unit: 'Stk', quantity: 20, stock: 1, order_limit: 10)
      planners = [ArticleAvailabilityPlanner.new(article).tap { it.start_processing(future_box) }]

      combination = described_class.new(20, planners, only: :immediate).select

      expect(combination).to eq(article.id => 1)
      expect(described_class.new(40, planners, only: :immediate).select).to eq({})
    end

    it 'with only: :orderable ignores stock', :aggregate_failures do
      future_box = create(:box, datetime: 2.days.from_now)
      article = create(:article, ingredient:, supplier:, packing_type: :piece, unit: 'Stk', quantity: 20, stock: 5, order_limit: 3)
      planners = [ArticleAvailabilityPlanner.new(article).tap { it.start_processing(future_box) }]

      combination = described_class.new(40, planners, only: :orderable).select

      expect(combination).to eq(article.id => 2)
      expect(planners.first.immediate_packages).to eq(5)
    end
  end
end
