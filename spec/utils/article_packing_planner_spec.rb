# frozen_string_literal: true

require 'rails_helper'

# Characterization specs for the ArticlePackingPlanner.
#
# The planner turns "what each group needs per box" (ingredient demand, read
# from the group_box_ingredient_unit_caches materialized view) into "which
# concrete articles to pack" (GroupBoxArticle), plus the side outputs
# ArticleBoxOrderRequirement (what still has to be ordered) and
# MissingIngredient (demand that cannot be covered at all).
#
# These specs pin down planner behaviour so it can be refactored safely.
# The "PROBLEM CASE" contexts document scenarios that used to be handled
# suboptimally (greedy package selection and unfair scarcity sharing).
#
# Demand is injected via the :demand_cache helper (see spec/support/demand_cache.rb),
# which swaps the read-only materialized view for a writable table for the
# duration of the example.
RSpec.describe ArticlePackingPlanner, :demand_cache do
  let(:ingredient) { create(:ingredient) }
  let(:supplier) { create(:supplier) }
  let(:group) { create(:group) }
  # Default box sits "now"; with the default 24h supplier delivery time nothing
  # can be ordered in time for it, so these boxes are covered from stock only.
  # That keeps the stock-only cases deterministic (no order requirements leak in).
  let(:box) { create(:box) }

  # A counted unit so piece packages read naturally ("Stk" = Stück/pieces).
  # Only units in the `units` table (plus g/ml) pass article validation.
  before { Unit.create!(name: 'Stk') }

  describe 'covering demand from stock' do
    it 'packs whole packages when the demand is an exact multiple of a package', :aggregate_failures do
      # A 10-piece package, plenty in stock. Demand of 30 divides evenly, so the
      # main reservation loop (required.divmod(article.quantity)) consumes it
      # completely and no remainder/filling logic runs.
      article = create(:article, ingredient:, supplier:, packing_type: :piece, unit: 'Stk', quantity: 10, stock: 5)
      add_demand(group:, box:, ingredient:, quantity: 30, unit: 'Stk')

      described_class.new.run

      expect(GroupBoxArticle.where(group:, box:, article:).sum(:quantity)).to eq(3)
      expect(MissingIngredient.count).to eq(0)
    end

    it 'records what was pulled from stock as an order requirement with quantity 0' do
      # Whenever stock is touched the planner emits an ArticleBoxOrderRequirement
      # so downstream views know how much of the plan is already on hand. Nothing
      # needs to be ordered here, hence quantity 0 but stock > 0.
      article = create(:article, ingredient:, supplier:, packing_type: :piece, unit: 'Stk', quantity: 10, stock: 5)
      add_demand(group:, box:, ingredient:, quantity: 30, unit: 'Stk')

      described_class.new.run

      requirement = ArticleBoxOrderRequirement.find_by(article:, box:)
      expect(requirement).to have_attributes(quantity: 0, stock: 3, ordered: 0)
    end

    it 'covers 120 exactly with 4x30 rather than overshooting with 1x100 + 1x30', :aggregate_failures do
      # ArticlePiecePackageSelector minimises overshoot first, then package count.
      big = create(:article, ingredient:, supplier:, packing_type: :piece, unit: 'Stk', quantity: 100, stock: 10)
      small = create(:article, ingredient:, supplier:, packing_type: :piece, unit: 'Stk', quantity: 30, stock: 10)
      add_demand(group:, box:, ingredient:, quantity: 120, unit: 'Stk')

      described_class.new.run

      expect(GroupBoxArticle.where(group:, box:, article: big).sum(:quantity)).to eq(0)
      expect(GroupBoxArticle.where(group:, box:, article: small).sum(:quantity)).to eq(4)
      expect(MissingIngredient.count).to eq(0)
    end
  end

  # Replays the plan's reservations for article in box and returns the planner.
  # Stock is always drawn before incoming orders, so one immediate reservation
  # reproduces the recorded stock/ordered split.
  def planner_after_box(article, box)
    planner = ArticleAvailabilityPlanner.new(article.reload).tap { it.start_processing(box) }
    abor = ArticleBoxOrderRequirement.find_by(article:, box:)
    if abor
      planner.reserve(abor.stock + abor.ordered, only: :immediate)
      planner.reserve(abor.quantity, only: :orderable)
    end
    planner
  end

  def expect_capacity_exhausted_for_ingredient!(box:, ingredient:, unit:, missing_required: true)
    expect(MissingIngredient.where(box:, ingredient:, unit:).where('quantity > 0')).to exist if missing_required

    Article.where(ingredient:, unit:).find_each do |article|
      planner = planner_after_box(article, box)
      expect(planner).not_to be_available,
                             "article #{article.id} still has #{planner.immediate_packages} packages or can order more"
    end
  end

  # ---------------------------------------------------------------------------
  # Regressions found by script/battle_test_article_packing_planner.rb
  # ---------------------------------------------------------------------------
  describe 'battle-test regressions' do
    it 'reports missing pieces when stock cannot cover demand', :aggregate_failures do
      # Selector packs the best partial combination from stock; the rest is missing.
      create(:article, ingredient:, supplier:, packing_type: :piece, unit: 'Stk', quantity: 16, stock: 1)
      add_demand(group:, box:, ingredient:, quantity: 32, unit: 'Stk')

      described_class.new.run

      packed_pieces =
        GroupBoxArticle.where(group:, box:).joins(:article).sum('group_box_articles.quantity * articles.quantity')
      expect(packed_pieces).to eq(16)
      missing = MissingIngredient.find_by(group:, box:, ingredient:)
      expect(missing).to have_attributes(unit: 'Stk', quantity: 16)
    end

    it 'merges fair-sharing stock and order passes into one GroupBoxArticle row', :aggregate_failures do
      # Fair sharing calls add_required_articles twice per group (immediate, then
      # orderable). insert_all unique_by must not drop the first batch of rows.
      future_box = create(:box, datetime: 2.days.from_now)
      other_group = create(:group)
      article = create(:article, :bulk, ingredient:, supplier:, stock: 100, order_limit: 50)
      add_demand(group:, box: future_box, ingredient:, quantity: 100, unit: 'g')
      add_demand(group: other_group, box: future_box, ingredient:, quantity: 100, unit: 'g')

      described_class.new.run

      # First group: 50g immediate stock + 50g ordered, merged into a single row.
      expect(GroupBoxArticle.where(group:, box: future_box, article:).sum(:quantity)).to eq(100)
      expect(GroupBoxArticle.where(group:, box: future_box, article:).count).to eq(1)
      # Second group: other half of stock, remainder missing once order limit is exhausted.
      expect(GroupBoxArticle.where(group: other_group, box: future_box, article:).sum(:quantity)).to eq(50)
      missing = MissingIngredient.find_by(group: other_group, box: future_box, ingredient:)
      expect(missing.quantity.to_i).to eq(50)
      # Order requirements are per box: all stock plus one shared order batch.
      requirement = ArticleBoxOrderRequirement.find_by(article:, box: future_box)
      expect(requirement).to have_attributes(stock: 100, quantity: 50, ordered: 0)
    end

    # Invariant #17 — capacity_exhausted_when_missing
    describe 'capacity exhausted when missing' do
      it 'leaves no stock on the shelf when a shortfall is reported', :aggregate_failures do
        # Demand exceeds all on-hand packages (battle invariant #17).
        article = create(:article, ingredient:, supplier:, packing_type: :piece, unit: 'Stk', quantity: 10, stock: 2)
        add_demand(group:, box:, ingredient:, quantity: 35, unit: 'Stk')

        described_class.new.run

        expect(GroupBoxArticle.where(group:, box:, article:).sum(:quantity)).to eq(2)
        missing = MissingIngredient.find_by(group:, box:, ingredient:)
        expect(missing).to have_attributes(unit: 'Stk', quantity: 15)
        expect_capacity_exhausted_for_ingredient!(box:, ingredient:, unit: 'Stk')
      end

      it 'assigns the last stock package when the first pass stops one pack short', :aggregate_failures do
        # Best-partial selection kept one 10-pack on the shelf for demand 26;
        # exhaust_remaining_capacity! should overshoot and clear the gap.
        article = create(:article, ingredient:, supplier:, packing_type: :piece, unit: 'Stk', quantity: 10, stock: 3)
        add_demand(group:, box:, ingredient:, quantity: 26, unit: 'Stk')

        described_class.new.run

        expect(GroupBoxArticle.where(group:, box:, article:).sum(:quantity)).to eq(3)
        expect(MissingIngredient.where(group:, box:, ingredient:)).not_to exist
        expect_capacity_exhausted_for_ingredient!(box:, ingredient:, unit: 'Stk', missing_required: false)
      end

      it 'orders every available package when demand exceeds the order limit', :aggregate_failures do
        # Orderable-only piece selection returned {} once shortfall passed the
        # remaining limit, leaving dozens of orderable packages unused.
        future_box = create(:box, datetime: 2.days.from_now)
        article = create(:article, ingredient:, supplier:, packing_type: :piece, unit: 'Stk',
                                   quantity: 10, stock: 0, order_limit: 4)
        add_demand(group:, box: future_box, ingredient:, quantity: 50, unit: 'Stk')

        described_class.new.run

        expect(GroupBoxArticle.where(group:, box: future_box, article:).sum(:quantity)).to eq(4)
        missing = MissingIngredient.find_by(group:, box: future_box, ingredient:)
        expect(missing).to have_attributes(unit: 'Stk', quantity: 10)
        requirement = ArticleBoxOrderRequirement.find_by(article:, box: future_box)
        expect(requirement).to have_attributes(stock: 0, quantity: 4, ordered: 0)
        expect_capacity_exhausted_for_ingredient!(box: future_box, ingredient:, unit: 'Stk')
      end

      it 'drains the shared order limit when fair sharing still leaves gaps', :aggregate_failures do
        # Sequential orderable pass only served the first group when shortfall
        # exceeded the limit; without partial orderable selection nothing was
        # ordered and the whole limit sat unused.
        future_box = create(:box, datetime: 2.days.from_now)
        other_group = create(:group)
        article = create(:article, ingredient:, supplier:, packing_type: :piece, unit: 'Stk',
                                   quantity: 10, stock: 0, order_limit: 4)
        add_demand(group:, box: future_box, ingredient:, quantity: 50, unit: 'Stk')
        add_demand(group: other_group, box: future_box, ingredient:, quantity: 50, unit: 'Stk')

        described_class.new.run

        expect(GroupBoxArticle.where(group:, box: future_box, article:).sum(:quantity)).to eq(4)
        expect(GroupBoxArticle.where(group: other_group, box: future_box, article:).sum(:quantity)).to eq(0)
        missing = MissingIngredient.where(box: future_box, ingredient:, unit: 'Stk')
                                   .where('quantity > 0')
        expect(missing.pluck(:group_id, :quantity).map { |group_id, quantity| [group_id, quantity.to_i] })
          .to contain_exactly([group.id, 10], [other_group.id, 50])
        requirement = ArticleBoxOrderRequirement.find_by(article:, box: future_box)
        expect(requirement).to have_attributes(stock: 0, quantity: 4, ordered: 0)
        expect_capacity_exhausted_for_ingredient!(box: future_box, ingredient:, unit: 'Stk')
      end

      it 'spends immediate stock left after proportional shortfall caps', :aggregate_failures do
        # allocate_shared_shortfall! caps each allowance at the entry shortfall, so
        # leftover immediate units stayed unused while groups still had gaps.
        other_group = create(:group)
        article = create(:article, ingredient:, supplier:, packing_type: :piece, unit: 'Stk',
                                   quantity: 10, stock: 7)
        add_demand(group:, box:, ingredient:, quantity: 55, unit: 'Stk')
        add_demand(group: other_group, box:, ingredient:, quantity: 55, unit: 'Stk')

        described_class.new.run

        expect(GroupBoxArticle.where(box:, article:).sum(:quantity)).to eq(7)
        missing = MissingIngredient.where(box:, ingredient:, unit: 'Stk')
        expect(missing.sum(:quantity).to_i).to eq(40)
        requirement = ArticleBoxOrderRequirement.find_by(article:, box:)
        expect(requirement).to have_attributes(stock: 7, quantity: 0, ordered: 0)
        expect_capacity_exhausted_for_ingredient!(box:, ingredient:, unit: 'Stk')
      end
    end
  end

  describe 'demand that cannot be covered' do
    it 'reports a missing ingredient when no article matches the demand unit', :aggregate_failures do
      # No article exists for this ingredient/unit at all, so the demand falls
      # straight through to MissingIngredient and no GroupBoxArticle is produced.
      add_demand(group:, box:, ingredient:, quantity: 50, unit: 'g')

      described_class.new.run

      expect(GroupBoxArticle.count).to eq(0)
      missing = MissingIngredient.find_by(group:, box:, ingredient:)
      expect(missing).to have_attributes(unit: 'g', quantity: 50)
    end
  end

  describe 'ordering to cover demand' do
    it 'splits coverage between stock and a new order requirement', :aggregate_failures do
      # Box far enough in the future that the supplier's next possible delivery
      # (now + 24h) lands before it, so the article becomes orderable for this box.
      # 30g in stock, demand 100g, no order limit. reserve() first drains stock
      # (30), then books the remaining 70 as an order requirement. The whole 100
      # still becomes a GroupBoxArticle because it will be packed once it arrives.
      future_box = create(:box, datetime: 2.days.from_now)
      article = create(:article, :bulk, ingredient:, supplier:, stock: 30)
      add_demand(group:, box: future_box, ingredient:, quantity: 100, unit: 'g')

      described_class.new.run

      expect(GroupBoxArticle.where(group:, box: future_box, article:).sum(:quantity)).to eq(100)
      requirement = ArticleBoxOrderRequirement.find_by(article:, box: future_box)
      expect(requirement).to have_attributes(quantity: 70, stock: 30, ordered: 0)
      expect(MissingIngredient.count).to eq(0)
    end
  end

  describe 'covering demand from an open order' do
    # The order has to cover the box: advance_orders_to only releases an order
    # once its coverage starts at or before the box, and the :order factory
    # defaults to a week out. The default box sits "now" with a 24h supplier
    # delivery time, so nothing is orderable on top and `quantity` stays 0.
    let(:open_coverage) { 1.day.ago..1.week.from_now }

    it 'records demand covered by an ordered order as `ordered`' do
      article = create(:article, ingredient:, supplier:, packing_type: :piece, unit: 'Stk', quantity: 10, stock: 0)
      order = create(:order, supplier:, state: :ordered, coverage: open_coverage)
      create(:order_article, order:, article:, quantity_ordered: 5, quantity_delivered: 0)
      add_demand(group:, box:, ingredient:, quantity: 30, unit: 'Stk')

      described_class.new.run

      expect(ArticleBoxOrderRequirement.find_by(article:, box:))
        .to have_attributes(quantity: 0, stock: 0, ordered: 3)
    end

    it 'uses the delivered quantity once the order has been delivered' do
      # Only 2 of the 5 ordered packages actually arrived, so the plan can rely
      # on 2 and the rest of the demand stays uncovered.
      article = create(:article, ingredient:, supplier:, packing_type: :piece, unit: 'Stk', quantity: 10, stock: 0)
      order = create(:order, supplier:, state: :delivered, coverage: open_coverage)
      create(:order_article, order:, article:, quantity_ordered: 5, quantity_delivered: 2)
      add_demand(group:, box:, ingredient:, quantity: 30, unit: 'Stk')

      described_class.new.run

      expect(ArticleBoxOrderRequirement.find_by(article:, box:))
        .to have_attributes(quantity: 0, stock: 0, ordered: 2)
    end
  end

  describe 'packed boxes' do
    it 'leaves an existing plan untouched and ignores new demand for it', :aggregate_failures do
      # Packed boxes are "done": process_ingredient_unit_in_box returns early and
      # update_plan only deletes rows for non-packed boxes. So a previously
      # planned GroupBoxArticle survives and freshly injected demand is ignored.
      packed_box = create(:box, :packed)
      article = create(:article, :bulk, ingredient:, supplier:, stock: 100)
      existing = create(:group_box_article, group:, box: packed_box, article:, quantity: 7)
      add_demand(group:, box: packed_box, ingredient:, quantity: 100, unit: 'g')

      described_class.new.run

      expect(existing.reload.quantity).to eq(7)
      expect(GroupBoxArticle.where(box: packed_box).count).to eq(1)
      expect(MissingIngredient.where(box: packed_box).count).to eq(0)
    end
  end

  # ---------------------------------------------------------------------------
  # PROBLEM CASE 1 — greedy packing overshoots and uses too many packages.
  #
  # "32 Würste geben 1x20 und 2x10": with a 20-piece and a 10-piece package and
  # a demand of 32, a greedy algorithm reserves 1x20 + 2x10 = 40 pieces across
  # three packages. The smallest coverable amount is still 40, but 2x20 reaches
  # it with only two packages.
  # ---------------------------------------------------------------------------
  describe 'PROBLEM CASE 1: optimal package selection' do
    it 'covers 32 with 2x20 instead of 1x20 + 2x10', :aggregate_failures do
      pack20 = create(:article, ingredient:, supplier:, packing_type: :piece, unit: 'Stk', quantity: 20, stock: 10)
      pack10 = create(:article, ingredient:, supplier:, packing_type: :piece, unit: 'Stk', quantity: 10, stock: 10)
      add_demand(group:, box:, ingredient:, quantity: 32, unit: 'Stk')

      described_class.new.run

      expect(GroupBoxArticle.where(group:, box:, article: pack20).sum(:quantity)).to eq(2)
      expect(GroupBoxArticle.where(group:, box:, article: pack10).sum(:quantity)).to eq(0)

      packed_pieces =
        GroupBoxArticle.where(group:, box:).joins(:article).sum('group_box_articles.quantity * articles.quantity')
      expect(packed_pieces).to eq(40)
      expect(GroupBoxArticle.where(group:, box:).sum(:quantity)).to eq(2)
    end
  end

  # ---------------------------------------------------------------------------
  # PROBLEM CASE 2 — scarce stock is not shared fairly between groups.
  #
  # When there is not enough stock for everyone (e.g. an order is delayed), each
  # group should receive a proportional share of the immediately available stock
  # before the remainder is reported as missing.
  # ---------------------------------------------------------------------------
  describe 'fractional demand' do
    # Demand is recipe quantities times hunger factors, so it is rarely whole.
    # A shortfall of a fraction of a unit used to hand the group all remaining
    # stock: 10.5 g packed 1000 g and left nothing for the next group.
    it 'rounds piece packages up (10.5 Stk -> 2x10)', :aggregate_failures do
      article = create(:article, ingredient:, supplier:, packing_type: :piece, unit: 'Stk', quantity: 10, stock: 5)
      add_demand(group:, box:, ingredient:, quantity: 10.5, unit: 'Stk')

      described_class.new.run

      expect(GroupBoxArticle.where(group:, box:, article:).sum(:quantity)).to eq(2)
      expect(MissingIngredient.count).to eq(0)
    end

    it 'rounds bulk up to whole units and leaves the rest for other groups', :aggregate_failures do
      article = create(:article, :bulk, ingredient:, supplier:, stock: 1000)
      other_group = create(:group)
      add_demand(group:, box:, ingredient:, quantity: 10.5, unit: 'g')
      add_demand(group: other_group, box:, ingredient:, quantity: 12.5, unit: 'g')

      described_class.new.run

      expect(GroupBoxArticle.where(group:, box:, article:).sum(:quantity)).to eq(11)
      expect(GroupBoxArticle.where(group: other_group, box:, article:).sum(:quantity)).to eq(13)
      expect(MissingIngredient.count).to eq(0)
    end
  end

  describe 'scarce piece packages' do
    it 'does not over-pack early groups at the expense of later ones', :aggregate_failures do
      # 600 Stk for 594 demanded. Ranking fewer packages above overshoot gave
      # the groups needing 103 and 99 four 30-packs each (120), leaving the last
      # group 65 of 102. Minimising overshoot keeps every group within one
      # 5-pack of its demand.
      pack30 = create(:article, ingredient:, supplier:, packing_type: :piece, unit: 'Stk', quantity: 30, stock: 14)
      create(:article, ingredient:, supplier:, packing_type: :piece, unit: 'Stk', quantity: 5, stock: 36, priority: 1)
      groups = [123, 103, 99, 147, 20, 102].map do |quantity|
        create(:group).tap { add_demand(group: it, box:, ingredient:, quantity:, unit: 'Stk') }
      end

      described_class.new.run

      packed = groups.map do |group|
        GroupBoxArticle.where(group:, box:).joins(:article).sum('group_box_articles.quantity * articles.quantity').to_i
      end
      expect(packed).to eq([125, 105, 100, 150, 20, 100])
      expect(MissingIngredient.where(box:).sum(:quantity)).to eq(2)
      expect(GroupBoxArticle.where(box:, article: pack30).sum(:quantity)).to eq(14)
    end
  end

  describe 'PROBLEM CASE 2: balanced scarcity' do
    it 'splits scarce stock proportionally between groups', :aggregate_failures do
      other_group = create(:group)
      # 100g in stock, not orderable in time (default box / 24h delivery), two
      # groups each needing 100g -> each should get 50g covered and 50g missing.
      article = create(:article, :bulk, ingredient:, supplier:, stock: 100)
      add_demand(group:, box:, ingredient:, quantity: 100, unit: 'g')
      add_demand(group: other_group, box:, ingredient:, quantity: 100, unit: 'g')

      described_class.new.run

      covered = GroupBoxArticle.where(box:, article:).pluck(:group_id, :quantity)
      missing = MissingIngredient.where(box:, ingredient:).pluck(:group_id, :quantity)
      normalize = ->(rows) { rows.map { |group_id, quantity| [group_id, quantity.to_i] } }

      expect(normalize.call(covered)).to contain_exactly([group.id, 50], [other_group.id, 50])
      expect(normalize.call(missing)).to contain_exactly([group.id, 50], [other_group.id, 50])
    end
  end
end
