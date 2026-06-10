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

  # ---------------------------------------------------------------------------
  # Regressions found by script/battle_test_article_packing_planner.rb
  # ---------------------------------------------------------------------------
  describe 'battle-test regressions' do
    it 'reports missing pieces after topping up with the last in-stock package', :aggregate_failures do
      # Optimised piece selection cannot reach the full demand from stock alone.
      # handle_remaining may add one whole package, but anything still short must
      # become MissingIngredient (not silently dropped).
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
