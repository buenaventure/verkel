# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ArticleAvailabilityPlanner do
  let(:supplier) { create(:supplier, delivery_time: 24) }
  let(:ingredient) { create(:ingredient) }
  # With a 24h delivery time, new orders can reach these boxes.
  let(:future_box) { create(:box, datetime: 2.days.from_now) }
  let(:later_box) { create(:box, datetime: 4.days.from_now) }

  def planner_for(article, box)
    described_class.new(article).tap { it.start_processing(box) }
  end

  def bulk_article(**attributes)
    create(:article, :bulk, ingredient:, supplier:, **attributes)
  end

  # An ordered delivery of quantity that arrives at the given time.
  def incoming(article, quantity, arriving:)
    order = create(:order, :ordered, supplier:, coverage: (arriving..(arriving + 2.weeks)))
    create(:order_article, order:, article:, quantity_ordered: quantity, quantity_delivered: 0)
  end

  def hoard(article, quantity, due:)
    Hoard.create!(article:, quantity:, until: due)
  end

  def missing(hoards)
    hoards.map { it.reload.missing_quantity }
  end

  # Reserves quantity; returns what was reserved and the planner's running
  # totals per source for the current box.
  def reservation(planner, quantity, only: nil)
    [planner.reserve(quantity, only:),
     { stock: planner.stock, ordered: planner.ordered, order_requirement: planner.order_requirement }]
  end

  describe '#reserve' do
    it 'drains stock, then incoming orders, then new orders', :aggregate_failures do
      article = bulk_article(stock: 30, order_limit: nil)
      incoming(article, 5, arriving: 2.days.ago)
      planner = planner_for(article, future_box)

      expect(reservation(planner, 10)).to eq([10, { stock: 10, ordered: 0, order_requirement: 0 }])
      expect(reservation(planner, 30)).to eq([30, { stock: 30, ordered: 5, order_requirement: 5 }])
    end

    it 'raises when quantity is negative' do
      planner = planner_for(bulk_article(stock: 10), create(:box))

      expect { planner.reserve(-1) }.to raise_error('quantity may not be negative')
    end

    it 'with only: :immediate does not place new orders' do
      planner = planner_for(bulk_article(stock: 30, order_limit: nil), future_box)

      expect(reservation(planner, 50, only: :immediate)).to eq([30, { stock: 30, ordered: 0, order_requirement: 0 }])
    end

    it 'with only: :orderable does not touch stock or incoming orders', :aggregate_failures do
      planner = planner_for(bulk_article(stock: 30, order_limit: 50), future_box)

      expect(reservation(planner, 20, only: :orderable)).to eq([20, { stock: 0, ordered: 0, order_requirement: 20 }])
      expect(planner.immediate_packages).to eq(30)
    end

    it 'raises when only is invalid' do
      planner = planner_for(bulk_article(stock: 10), create(:box))

      expect { planner.reserve(1, only: :full) }.to raise_error(ArgumentError, 'invalid only: :full')
    end

    it 'respects the article order limit', :aggregate_failures do
      planner = planner_for(bulk_article(stock: 0, order_limit: 15), future_box)

      expect(reservation(planner, 25)).to eq([15, { stock: 0, ordered: 0, order_requirement: 15 }])
      expect(planner.reserve(10)).to eq(0)
    end
  end

  describe '#orderable? and #available?' do
    it 'is not orderable when the box is before the supplier can deliver', :aggregate_failures do
      planner = planner_for(bulk_article(stock: 0, order_limit: 10), create(:box, datetime: Time.zone.now))

      expect(planner).not_to be_orderable
      expect(planner).not_to be_available
    end

    it 'is orderable when the box is after the earliest delivery date', :aggregate_failures do
      planner = planner_for(bulk_article(stock: 0, order_limit: 10), future_box)

      expect(planner).to be_orderable
      expect(planner).to be_available
    end
  end

  describe '#total_coverable_units' do
    it 'includes stock and the remaining order limit when orderable' do
      planner = planner_for(bulk_article(stock: 40, order_limit: 25), future_box)

      expect(planner.total_coverable_units).to eq(65)
    end
  end

  describe 'hoards' do
    it 'blocks hoarded stock until the hoard date passes', :aggregate_failures do
      article = bulk_article(stock: 100)
      hoard(article, 40, due: 1.day.from_now)

      expect(planner_for(article, create(:box, datetime: Time.zone.now)).immediate_packages).to eq(60)
      expect(planner_for(article.reload, future_box).immediate_packages).to eq(100)
    end

    it 'releases hoards due at the same box earliest first, whatever order they are stored in' do
      article = bulk_article(stock: 5)
      incoming(article, 2, arriving: 1.day.ago)
      # The large hoard is stored first, so an unordered query returns it first.
      hoards = [hoard(article, 10, due: future_box.datetime), hoard(article, 1, due: future_box.datetime - 1.hour)]

      planner_for(article, future_box)

      # The small hoard keeps 1 of the 5 blocked units; the large one gets the
      # other 4 and is short 10 - 4 - 2 incoming = 4. Large first would report 3.
      expect(missing(hoards)).to eq([4, 0])
    end

    it 'shares incoming goods between hoards released at the same box' do
      article = bulk_article(stock: 0)
      incoming(article, 5, arriving: 1.day.from_now)
      hoards = Array.new(3) { hoard(article, 5, due: future_box.datetime) }

      planner_for(article, future_box)

      # 15 hoarded and 5 arriving: the delivery backs one hoard, not all three.
      expect(missing(hoards)).to eq([0, 5, 5])
    end

    it 'does not let one delivery back hoards whose lifetimes overlap' do
      article = bulk_article(stock: 0)
      incoming(article, 5, arriving: 1.day.from_now)
      hoards = [hoard(article, 5, due: future_box.datetime), hoard(article, 5, due: later_box.datetime)]

      planner_for(article, future_box).start_processing(later_box)

      # The delivery backs the early hoard until its date; the late hoard is
      # active over the same days and has no backup of its own.
      expect(missing(hoards)).to eq([0, 5])
    end

    it 'counts deliveries that arrive after the last box but before a hoard ends' do
      article = bulk_article(stock: 0)
      incoming(article, 5, arriving: 2.days.from_now)
      backup = hoard(article, 5, due: 3.days.from_now)

      planner_for(article, create(:box, datetime: 1.day.from_now)).finish

      expect(missing([backup])).to eq([0])
    end
  end

  describe '#order_requirements?' do
    it 'becomes true once stock, incoming orders, or new orders are reserved' do
      planner = planner_for(bulk_article(stock: 5, order_limit: nil), future_box)

      expect { planner.reserve(8) }.to change(planner, :order_requirements?).from(false).to(true)
    end
  end
end
