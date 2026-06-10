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
# These specs pin down the *current* behaviour so the planner can be refactored
# safely. Two of the contexts (tagged "PROBLEM CASE") deliberately assert the
# present, suboptimal behaviour we want to improve later; their comments explain
# both why it happens today and what we would prefer instead.
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

    it 'tops up a sub-package remainder with one whole smallest package', :aggregate_failures do
      # Demand 120 against a 100-piece and a 30-piece package. The main loop
      # reserves 1x100 (remainder 20) and then 0x30 (20 < 30). The leftover 20
      # cannot be covered by a fraction of a package, so handle_remaining reserves
      # ONE whole package of the smallest available article (select_filling_article
      # = min by [quantity, priority]) -> a single 30, overshooting to 130.
      big = create(:article, ingredient:, supplier:, packing_type: :piece, unit: 'Stk', quantity: 100, stock: 10)
      small = create(:article, ingredient:, supplier:, packing_type: :piece, unit: 'Stk', quantity: 30, stock: 10)
      add_demand(group:, box:, ingredient:, quantity: 120, unit: 'Stk')

      described_class.new.run

      expect(GroupBoxArticle.where(group:, box:, article: big).sum(:quantity)).to eq(1)
      expect(GroupBoxArticle.where(group:, box:, article: small).sum(:quantity)).to eq(1)
      expect(MissingIngredient.count).to eq(0)
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
  # a demand of 32, the planner reserves 1x20 (remainder 12), then 1x10
  # (remainder 2), then tops the remaining 2 up with the *smallest* package, a
  # second 10. Result: 1x20 + 2x10 = 40 pieces across THREE packages.
  #
  # 40 is indeed the smallest coverable amount here, but it could be reached with
  # 2x20 (two packages) or a single 40 package. The current algorithm is greedy
  # and remainder-driven: it never reconsiders earlier choices to minimise the
  # number of packages (or total overshoot). This is the behaviour we want to
  # improve; the spec locks in today's output so a future optimiser can replace
  # it intentionally rather than by accident.
  # ---------------------------------------------------------------------------
  describe 'PROBLEM CASE 1: greedy package selection' do
    it 'covers 32 with 1x20 + 2x10 instead of 2x20', :aggregate_failures do
      pack20 = create(:article, ingredient:, supplier:, packing_type: :piece, unit: 'Stk', quantity: 20, stock: 10)
      pack10 = create(:article, ingredient:, supplier:, packing_type: :piece, unit: 'Stk', quantity: 10, stock: 10)
      add_demand(group:, box:, ingredient:, quantity: 32, unit: 'Stk')

      described_class.new.run

      expect(GroupBoxArticle.where(group:, box:, article: pack20).sum(:quantity)).to eq(1)
      expect(GroupBoxArticle.where(group:, box:, article: pack10).sum(:quantity)).to eq(2)

      # Documents the overshoot: 40 pieces packed for a demand of 32, and the
      # package count (3) is higher than the achievable optimum (2x20).
      packed_pieces =
        GroupBoxArticle.where(group:, box:).joins(:article).sum('group_box_articles.quantity * articles.quantity')
      expect(packed_pieces).to eq(40)
      expect(GroupBoxArticle.where(group:, box:).sum(:quantity)).to eq(3)
    end
  end

  # ---------------------------------------------------------------------------
  # PROBLEM CASE 2 — scarce stock is not shared fairly between groups.
  #
  # When there is not enough stock for everyone (e.g. an order is delayed), the
  # planner serves groups sequentially from one shared availability pool. The
  # first group(s) processed grab everything that is in stock; later groups find
  # the pool empty and end up fully in MissingIngredient.
  #
  # We would prefer to balance scarcity, so every group gets roughly the same
  # percentage of its needs (here ~50% each). The spec captures the current
  # all-or-nothing split. It asserts in an order-independent way (we don't rely
  # on which group the unordered demand query happens to serve first), only that
  # exactly one group is fully covered and the other fully missing.
  # ---------------------------------------------------------------------------
  describe 'PROBLEM CASE 2: unbalanced scarcity' do
    it 'gives one group everything and the other nothing instead of splitting 50/50', :aggregate_failures do
      other_group = create(:group)
      # 100g in stock, not orderable in time (default box / 24h delivery), two
      # groups each needing 100g -> only enough for one of them.
      article = create(:article, :bulk, ingredient:, supplier:, stock: 100)
      add_demand(group:, box:, ingredient:, quantity: 100, unit: 'g')
      add_demand(group: other_group, box:, ingredient:, quantity: 100, unit: 'g')

      described_class.new.run

      covered = GroupBoxArticle.where(box:, article:).pluck(:group_id, :quantity)
      missing = MissingIngredient.where(box:, ingredient:).pluck(:group_id, :quantity)

      expect(covered.size).to eq(1)
      expect(missing.size).to eq(1)
      # The lucky group gets the full 100g; the other gets none of it and is
      # fully missing -> the imbalance we want to fix (ideal would be 50/50).
      expect(covered.first.last).to eq(100)
      expect(missing.first.last).to eq(100)
      expect(covered.first.first).not_to eq(missing.first.first)
    end
  end
end
