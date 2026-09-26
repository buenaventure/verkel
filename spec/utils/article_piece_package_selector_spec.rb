# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ArticlePiecePackageSelector do
  let(:supplier) { create(:supplier, delivery_time: 24) }
  let(:ingredient) { create(:ingredient) }
  let(:box) { create(:box) }
  # With a 24h delivery time, new orders can reach this box.
  let(:future_box) { create(:box, datetime: 2.days.from_now) }

  before { Unit.create!(name: 'Stk') }

  def pack(quantity, **attributes)
    create(:article, ingredient:, supplier:, packing_type: :piece, unit: 'Stk', quantity:, **attributes)
  end

  def planners_for(*articles, box:)
    articles.map do |article|
      ArticleAvailabilityPlanner.new(article).tap { it.start_processing(box) }
    end
  end

  def select(required_units, *articles, only: nil, box: self.box)
    described_class.new(required_units, planners_for(*articles, box:), only:).select
  end

  describe '#select' do
    it 'returns an empty hash when nothing is required' do
      expect(select(0, pack(10, stock: 5))).to eq({})
    end

    it 'returns an empty hash when no article is available' do
      expect(select(20, pack(10, stock: 0))).to eq({})
    end

    it 'breaks an overshoot tie by package count (32 Stk -> 2x20)' do
      pack20 = pack(20, stock: 10)
      pack10 = pack(10, stock: 10, priority: 1)

      expect(select(32, pack20, pack10)).to eq(pack20.id => 2)
    end

    it 'minimises overshoot before package count (120 Stk -> 4x30, not 1x100 + 1x30)' do
      big = pack(100, stock: 10)
      small = pack(30, stock: 10)

      expect(select(120, big, small)).to eq(small.id => 4)
    end

    it 'rounds the package count up for fractional demand (10.5 Stk -> 2x10)' do
      article = pack(10, stock: 5)

      expect(select(BigDecimal('10.5'), article)).to eq(article.id => 2)
    end

    it 'prefers lower-priority articles when package count and overshoot tie' do
      preferred = pack(20, stock: 5, priority: 0)
      alternate = pack(20, stock: 5, priority: 5)

      expect(select(20, alternate, preferred)).to eq(preferred.id => 1)
    end

    it 'returns the best partial combination when demand exceeds available stock' do
      article = pack(16, stock: 1)

      expect(select(32, article)).to eq(article.id => 1)
    end

    it 'with only: :immediate considers only stock and incoming orders', :aggregate_failures do
      article = pack(20, stock: 1, order_limit: 10)

      expect(select(40, article, only: :immediate, box: future_box)).to eq(article.id => 1)
      expect(select(40, article, box: future_box)).to eq(article.id => 2)
    end

    it 'with only: :orderable ignores stock', :aggregate_failures do
      article = pack(20, stock: 5, order_limit: 1)

      expect(select(40, article, only: :orderable, box: future_box)).to eq(article.id => 1)
      expect(select(40, article, box: future_box)).to eq(article.id => 2)
    end
  end
end
