# frozen_string_literal: true

# Property-style battle tests for {ArticlePackingPlanner}.
#
# Invariants checked after each random scenario:
#
# 1. demand_fulfillment — missing quantity equals unmet demand; packed + missing
#    covers every group's need (piece overshoot is allowed).
# 2. non_negative_outputs — no negative quantities in plan tables.
# 3. article_ingredient_match — packed articles belong to the demanded ingredient/unit.
# 4. package_accounting — per article and box, packed packages equal stock + ordered + to-order.
# 5. stock_not_exceeded — total stock drawn per article never exceeds starting stock.
# 6. order_limit_respected — new order requirements stay within each article's order limit.
# 7. orders_only_when_deliverable — nothing is ordered for boxes before delivery is possible.
# 8. idempotent_plan — running the planner twice yields identical output.
# 9. packed_boxes_preserved — pre-existing plans for packed boxes are left untouched.
# 10. no_demand_leak_into_packed_boxes — packed boxes do not gain new plan rows.
# 11. whole_piece_packages — piece articles are packed in whole package counts.
# 12. uniqueness — at most one row per natural key in each output table.
# 13. total_accounted — packed ingredient units plus missing never fall short of demand.
# 14. hoards_respected — hoarded stock stays blocked until its release date; missing_quantity
#     matches the release formula and stays within bounds.
# 15. incoming_order_not_exceeded — stock drawn from already-ordered deliveries per box
#     never exceeds what had arrived by that box's datetime.
# 16. hoard_shortfall_separate_from_abor — hoard gaps are recorded only on Hoard rows;
#     ArticleBoxOrderRequirement.quantity reflects pack-demand orders only (the two may
#     coexist but are never merged during planning).
# 17. capacity_exhausted_when_missing — when a group still has unmet demand for an
#     ingredient in a box, every article for that ingredient has no stock, incoming
#     orders, or orderable capacity left after that box (chronologically replayed).
# 18. overshoot_bounded — no group gets a whole package more than it needs: packed
#     units exceed demand by less than the largest package of that ingredient/unit.
#
# Run via: RAILS_ENV=test bin/rails runner script/battle_test_article_packing_planner.rb
class ArticlePackingPlannerBattleTest
  class InvariantViolation < StandardError; end

  PACKING_TYPES = %i[bulk piece].freeze
  BULK_UNITS = %w[g].freeze
  PIECE_UNITS = %w[Stk].freeze
  PACKAGE_SIZES = [1, 5, 10, 20, 30, 100].freeze
  ORDER_STATES = Order.states.keys.map(&:to_sym).freeze
  # Demand in a unit no article is sold in, so it can only be reported missing.
  UNSOLD_UNIT = 'ml'

  Scenario = Data.define(
    :trial,
    :seed,
    :demands,
    :articles_by_id,
    :initial_stock,
    :initial_order_limits,
    :packed_box_snapshots,
    :suppliers_by_id,
    :boxes_by_id
  )

  # Runs every trial and returns the battle test, which can then be asked #passed?.
  def self.run(trials: 25, seed: Random.new_seed, verbose: false, out: $stdout)
    new(trials:, seed:, verbose:, out:).tap(&:run)
  end

  def initialize(trials:, seed:, verbose:, out: $stdout)
    @trials = trials
    @rng = Random.new(seed)
    @seed = seed
    @verbose = verbose
    @out = out
    @failures = []
    @demand_cache_ready = false
  end

  def run
    @out.puts "ArticlePackingPlanner battle test — #{@trials} trials, seed #{@seed}"
    @trials.times { run_trial(it) }
    report
  end

  def passed? = @failures.empty?

  private

  def run_trial(trial)
    @demand_cache_ready = false
    ActiveRecord::Base.transaction do
      scenario = build_scenario(trial)
      @out.print '.' if @verbose
      ArticlePackingPlanner.new.run
      verify_invariants!(scenario)
      verify_idempotency!(scenario)
      raise ActiveRecord::Rollback
    end
  rescue InvariantViolation => e
    @failures << { trial:, message: e.message }
    @out.print 'F' if @verbose
  end

  def build_scenario(trial)
    clear_planner_outputs!
    fake_demand_cache! unless @demand_cache_ready
    @demand_cache_ready = true
    ensure_units!

    suppliers = Array.new(rand_range(1, 2)) { create_supplier }
    ingredients = Array.new(rand_range(2, 4)) { FactoryBot.create(:ingredient) }
    boxes = create_boxes
    packed_boxes = boxes.select(&:packed?)
    articles = create_articles(ingredients, suppliers)
    lane_stock = create_packing_lane_stocks!(articles, boxes)
    create_hoards!(articles, boxes)
    create_orders!(articles, boxes)
    groups = Array.new(rand_range(2, 6)) { FactoryBot.create(:group) }
    demands = create_demands(groups, boxes, ingredients, articles)
    seed_packed_box_plans!(packed_boxes, groups, articles)
    demands.concat(record_seeded_packed_demands(packed_boxes))
    packed_snapshots = snapshot_packed_box_articles(packed_boxes)

    Scenario.new(
      trial:,
      seed: @seed,
      demands:,
      articles_by_id: articles.index_by(&:id),
      initial_stock: articles.to_h { [it.id, it.stock + lane_stock.fetch(it.id, 0)] },
      initial_order_limits: articles.to_h { [it.id, it.current_order_limit] },
      packed_box_snapshots: packed_snapshots,
      suppliers_by_id: suppliers.index_by(&:id),
      boxes_by_id: boxes.index_by(&:id)
    )
  end

  def verify_invariants!(scenario)
    check_demand_fulfillment!(scenario)
    check_overshoot_bounded!(scenario)
    check_non_negative_outputs!
    check_article_ingredient_match!(scenario)
    check_package_accounting!(scenario)
    check_stock_not_exceeded!(scenario)
    check_order_limit_respected!(scenario)
    check_orders_only_when_deliverable!(scenario)
    check_packed_boxes_preserved!(scenario)
    check_no_demand_leak_into_packed_boxes!(scenario)
    check_whole_piece_packages!(scenario)
    check_uniqueness!
    check_hoards_respected!(scenario)
    check_capacity_exhausted_when_missing!(scenario)
    check_article_availability_replay!(scenario)
  end

  def verify_idempotency!(scenario)
    first = snapshot_plan
    ArticlePackingPlanner.new.run
    second = snapshot_plan
    return if first == second

    fail_invariant!(scenario, 'idempotent_plan',
                    'running the planner twice produced different output')
  end

  def check_demand_fulfillment!(scenario)
    scenario.demands.each do |demand|
      box = Box.find(demand[:box_id])
      next if box.packed?

      packed = packed_ingredient_units(demand)
      missing = MissingIngredient.find_by(
        group_id: demand[:group_id],
        box_id: demand[:box_id],
        ingredient_id: demand[:ingredient_id],
        unit: demand[:unit]
      )&.quantity.to_d
      demand_qty = demand[:quantity].to_d
      expected_missing = [demand_qty - packed, 0].max

      accounted = packed + missing
      next if accounted >= demand_qty && missing == expected_missing

      fail_invariant!(
        scenario,
        'demand_fulfillment',
        "group #{demand[:group_id]} box #{demand[:box_id]} " \
        "ingredient #{demand[:ingredient_id]} #{demand[:unit]}: " \
        "demand=#{demand_qty}, packed=#{packed}, missing=#{missing}, " \
        "accounted=#{accounted}, expected_missing=#{expected_missing}"
      )
    end
  end

  def check_overshoot_bounded!(scenario)
    largest_package = scenario.articles_by_id.values
                              .group_by { [it.ingredient_id, it.unit] }
                              .transform_values { |articles| articles.map { it.quantity.to_d }.max }
    packed_box_ids = Box.packed.pluck(:id).to_set
    scenario.demands.each do |demand|
      next if packed_box_ids.include?(demand[:box_id])

      limit = largest_package[[demand[:ingredient_id], demand[:unit]]]
      next unless limit

      overshoot = packed_ingredient_units(demand) - demand[:quantity].to_d
      next if overshoot < limit

      fail_invariant!(
        scenario,
        'overshoot_bounded',
        "group #{demand[:group_id]} box #{demand[:box_id]} ingredient #{demand[:ingredient_id]} " \
        "#{demand[:unit]}: demand=#{demand[:quantity].to_d}, overshoot=#{overshoot}, largest package=#{limit}"
      )
    end
  end

  def check_non_negative_outputs!
    [GroupBoxArticle, MissingIngredient, ArticleBoxOrderRequirement].each do |model|
      model.find_each do |row|
        row.attributes.each do |attr, value|
          next unless %w[quantity stock ordered].include?(attr)
          next unless value.to_d.negative?

          fail_invariant!(nil, 'non_negative_outputs', "#{model.name}##{row.id}.#{attr} is negative (#{value})")
        end
      end
    end
  end

  def check_article_ingredient_match!(scenario)
    packed_box_ids = Box.packed.pluck(:id).to_set
    demand_keys = scenario.demands.to_set { [it[:group_id], it[:box_id], it[:ingredient_id], it[:unit]] }
    GroupBoxArticle.includes(:article).find_each do |gba|
      next if packed_box_ids.include?(gba.box_id)

      article = gba.article
      next if demand_keys.include?([gba.group_id, gba.box_id, article.ingredient_id, article.unit])

      fail_invariant!(
        scenario,
        'article_ingredient_match',
        "GroupBoxArticle #{gba.id} packs article #{article.id} " \
        "without matching demand for #{article.ingredient_id}/#{article.unit}"
      )
    end
  end

  def check_package_accounting!(scenario)
    ArticleBoxOrderRequirement.find_each do |abor|
      packed = GroupBoxArticle.where(article_id: abor.article_id, box_id: abor.box_id).sum(:quantity).to_d
      allocated = abor.stock.to_d + abor.ordered.to_d + abor.quantity.to_d
      next if packed == allocated

      fail_invariant!(
        scenario,
        'package_accounting',
        "article #{abor.article_id} box #{abor.box_id}: packed #{packed} packages " \
        "!= stock(#{abor.stock}) + ordered(#{abor.ordered}) + to_order(#{abor.quantity})"
      )
    end

    packed_box_ids = Box.packed.pluck(:id).to_set
    GroupBoxArticle.find_each do |gba|
      next if packed_box_ids.include?(gba.box_id)
      next if ArticleBoxOrderRequirement.exists?(article_id: gba.article_id, box_id: gba.box_id)

      fail_invariant!(
        scenario,
        'package_accounting',
        "GroupBoxArticle #{gba.id} has no ArticleBoxOrderRequirement for article #{gba.article_id} box #{gba.box_id}"
      )
    end
  end

  def check_stock_not_exceeded!(scenario)
    ArticleBoxOrderRequirement.group(:article_id).sum(:stock).each do |article_id, used|
      limit = scenario.initial_stock.fetch(article_id, 0).to_d
      next if used.to_d <= limit

      fail_invariant!(
        scenario,
        'stock_not_exceeded',
        "article #{article_id}: stock used #{used} exceeds initial #{limit}"
      )
    end
  end

  def check_order_limit_respected!(scenario)
    ArticleBoxOrderRequirement.group(:article_id).sum(:quantity).each do |article_id, ordered|
      limit = scenario.initial_order_limits.fetch(article_id)
      next if limit.nil?
      next if ordered.to_d <= limit.to_d

      fail_invariant!(
        scenario,
        'order_limit_respected',
        "article #{article_id}: ordered #{ordered} exceeds limit #{limit}"
      )
    end
  end

  def check_orders_only_when_deliverable!(scenario)
    ArticleBoxOrderRequirement.includes(:box, article: :supplier).where('quantity > 0').find_each do |abor|
      delivery = abor.article.supplier.next_possible_delivery
      next if abor.box.datetime >= delivery

      fail_invariant!(
        scenario,
        'orders_only_when_deliverable',
        "article #{abor.article_id} box #{abor.box_id} orders #{abor.quantity} packages " \
        "but delivery earliest at #{delivery} (box at #{abor.box.datetime})"
      )
    end
  end

  def check_packed_boxes_preserved!(scenario)
    scenario.packed_box_snapshots.each do |key, quantity|
      gba = GroupBoxArticle.find_by(group_id: key[0], box_id: key[1], article_id: key[2])
      current = gba&.quantity.to_d
      next if current == quantity.to_d

      fail_invariant!(
        scenario,
        'packed_boxes_preserved',
        "packed box plan changed for #{key.inspect}: was #{quantity}, now #{current}"
      )
    end
  end

  def check_no_demand_leak_into_packed_boxes!(scenario)
    packed_box_ids = Box.packed.pluck(:id)
    return if packed_box_ids.empty?

    if MissingIngredient.exists?(box_id: packed_box_ids)
      fail_invariant!(
        scenario,
        'no_demand_leak_into_packed_boxes',
        'packed box gained MissingIngredient rows'
      )
    end

    allowed = scenario.packed_box_snapshots.keys.to_set
    GroupBoxArticle.where(box_id: packed_box_ids).pluck(:group_id, :box_id, :article_id).each do |key|
      next if allowed.include?(key)

      fail_invariant!(
        scenario,
        'no_demand_leak_into_packed_boxes',
        "packed box gained unexpected GroupBoxArticle #{key.inspect}"
      )
    end
  end

  def check_whole_piece_packages!(scenario)
    GroupBoxArticle.includes(:article).find_each do |gba|
      next unless gba.article.piece?
      next if gba.quantity == gba.quantity.to_i

      fail_invariant!(
        scenario,
        'whole_piece_packages',
        "GroupBoxArticle #{gba.id} has fractional package count #{gba.quantity}"
      )
    end
  end

  def check_uniqueness!
    assert_unique!(GroupBoxArticle, %i[group_id box_id article_id], 'group_box_articles')
    assert_unique!(MissingIngredient, %i[group_id box_id ingredient_id unit], 'missing_ingredients')
    assert_unique!(ArticleBoxOrderRequirement, %i[article_id box_id], 'article_box_order_requirements')
  end

  def check_capacity_exhausted_when_missing!(scenario)
    packed_box_ids = Box.packed.pluck(:id).to_set

    MissingIngredient.where('quantity > 0').find_each do |missing|
      next if packed_box_ids.include?(missing.box_id)

      box = Box.find(missing.box_id)
      Article.where(ingredient_id: missing.ingredient_id, unit: missing.unit).find_each do |article|
        remaining = remaining_capacity_after_box(scenario, article, box)
        next if capacity_exhausted?(remaining)

        fail_invariant!(
          scenario,
          'capacity_exhausted_when_missing',
          "box #{box.id} ingredient #{missing.ingredient_id} #{missing.unit} has missing " \
          "#{missing.quantity.to_d} but article #{article.id} still has " \
          "stock=#{remaining[:stock]}, ordered=#{remaining[:ordered]}, " \
          "orderable=#{remaining[:orderable].inspect}"
        )
      end
    end
  end

  # Replays the planner's reservations for one article up to target_box. The
  # replay releases hoards, and ArticleAvailabilityPlanner saves each released
  # hoard, so it runs in a rolled-back savepoint: otherwise it would overwrite
  # the missing_quantity values that check_article_availability_replay! verifies.
  def remaining_capacity_after_box(scenario, article, target_box)
    remaining = nil
    ActiveRecord::Base.transaction(requires_new: true) do
      planner = ArticleAvailabilityPlanner.new(article)
      processed_boxes(scenario, article.ingredient_id, article.unit)
        .select { |box| box.datetime <= target_box.datetime }
        .each do |box|
          planner.start_processing(box)
          abor = ArticleBoxOrderRequirement.find_by(article_id: article.id, box_id: box.id)
          next unless abor

          planner.send(:reserve_stock, abor.stock.to_d)
          planner.send(:reserve_ordered, abor.ordered.to_d)
          planner.send(:reserve_orderable, abor.quantity.to_d)
        end

      remaining = {
        stock: planner.instance_variable_get(:@available_stock).to_d,
        ordered: planner.instance_variable_get(:@available_ordered).to_d,
        orderable: planner.instance_variable_get(:@available_to_order),
        orderable_flag: planner.orderable?
      }
      raise ActiveRecord::Rollback
    end
    remaining
  end

  def capacity_exhausted?(remaining)
    return false unless remaining[:stock].zero? && remaining[:ordered].zero?
    return true unless remaining[:orderable_flag]

    limit = remaining[:orderable]
    limit.nil? ? false : limit.to_d.zero?
  end

  def check_hoards_respected!(scenario)
    Hoard.where(article_id: scenario.articles_by_id.keys).find_each do |hoard|
      missing = hoard.missing_quantity.to_d
      quantity = hoard.quantity.to_d
      next if missing.between?(0, quantity)

      fail_invariant!(
        scenario,
        'hoards_respected',
        "hoard #{hoard.id} missing_quantity #{missing} outside 0..#{quantity}"
      )
    end
  end

  def check_article_availability_replay!(scenario)
    scenario.articles_by_id.each_key do |article_id|
      verify_article_lifecycle!(scenario, article_id)
    end
  end

  def verify_article_lifecycle!(scenario, article_id)
    article = scenario.articles_by_id.fetch(article_id)
    hoards = Hoard.where(article_id:).to_a
    order_articles = OrderArticle.where(article_id:).includes(:order).to_a
    abors = ArticleBoxOrderRequirement.where(article_id:).index_by(&:box_id)
    return if hoards.empty? && order_articles.empty? && abors.empty?

    simulator = ArticleLifecycleSimulator.new(
      total_stock: scenario.initial_stock.fetch(article_id),
      hoards:,
      order_articles:
    )

    processed_boxes(scenario, article.ingredient_id, article.unit).each do |box|
      simulator.process_box(box.datetime, abor: abors[box.id])
    end
    simulator.finish_remaining_hoards

    hoards.each do |hoard|
      expected = simulator.expected_missing.fetch(hoard.id, 0).to_d
      actual = hoard.reload.missing_quantity.to_d
      next if actual == expected

      fail_invariant!(
        scenario,
        'hoards_respected',
        "hoard #{hoard.id} missing_quantity #{actual} != expected #{expected} after replay"
      )
    end
  rescue HoardInvariantError => e
    invariant = e.message.include?('ordered draw') ? 'incoming_order_not_exceeded' : 'hoards_respected'
    fail_invariant!(scenario, invariant, "article #{article_id}: #{e.message}")
  end

  # The boxes in which the planner touches articles of this ingredient and unit:
  # those with demand for it, oldest first. Packed boxes are skipped by the
  # planner before it advances any article, so they are left out here too.
  # Loaded from the database so datetimes carry the same precision the
  # planner compares hoard and order dates against.
  def processed_boxes(scenario, ingredient_id, unit)
    box_ids = scenario.demands.filter_map do |demand|
      demand[:box_id] if demand[:ingredient_id] == ingredient_id && demand[:unit] == unit
    end
    Box.where(id: box_ids.uniq).where.not(status: :packed).order(:datetime)
  end

  def assert_unique!(model, columns, label)
    duplicates = model.group(columns).having('COUNT(*) > 1').count
    return if duplicates.empty?

    fail_invariant!(nil, 'uniqueness', "duplicate #{label} keys: #{duplicates.keys.first(3).join(', ')}")
  end

  def packed_ingredient_units(demand)
    GroupBoxArticle
      .joins(:article)
      .where(
        group_id: demand[:group_id],
        box_id: demand[:box_id],
        articles: { ingredient_id: demand[:ingredient_id], unit: demand[:unit] }
      )
      .sum(Arel.sql('group_box_articles.quantity * articles.quantity'))
      .to_d
  end

  def snapshot_plan
    {
      group_box_articles: GroupBoxArticle.order(:group_id, :box_id, :article_id)
                                         .pluck(:group_id, :box_id, :article_id, :quantity),
      missing_ingredients: MissingIngredient.order(:group_id, :box_id, :ingredient_id, :unit)
                                            .pluck(:group_id, :box_id, :ingredient_id, :unit, :quantity),
      order_requirements: ArticleBoxOrderRequirement.order(:article_id, :box_id)
                                                    .pluck(:article_id, :box_id, :quantity, :stock, :ordered)
    }
  end

  def record_seeded_packed_demands(packed_boxes)
    packed_boxes.flat_map do |box|
      GroupBoxArticle.where(box:).map do |gba|
        {
          group_id: gba.group_id,
          box_id: gba.box_id,
          ingredient_id: gba.article.ingredient_id,
          unit: gba.article.unit,
          quantity: gba.quantity * gba.article.quantity
        }
      end
    end
  end

  def seed_packed_box_plans!(packed_boxes, groups, articles)
    packed_boxes.each do |box|
      next if @rng.rand < 0.5

      article = articles.sample(random: @rng)
      group = groups.sample(random: @rng)
      FactoryBot.create(:group_box_article, group:, box:, article:, quantity: @rng.rand(1..5))
    end
  end

  def snapshot_packed_box_articles(packed_boxes)
    return {} if packed_boxes.empty?

    GroupBoxArticle.where(box_id: packed_boxes.map(&:id))
                   .pluck(:group_id, :box_id, :article_id, :quantity)
                   .to_h { |(group_id, box_id, article_id, quantity)| [[group_id, box_id, article_id], quantity] }
  end

  def clear_planner_outputs!
    GroupBoxArticle.delete_all
    MissingIngredient.delete_all
    ArticleBoxOrderRequirement.delete_all
  end

  def fake_demand_cache!
    connection = ActiveRecord::Base.connection
    drop_demand_cache_object!(connection)
    connection.execute(<<~SQL.squish)
      CREATE TABLE group_box_ingredient_unit_caches (
        group_id bigint NOT NULL,
        box_id bigint NOT NULL,
        ingredient_id bigint NOT NULL,
        unit character varying,
        quantity numeric
      )
    SQL
  end

  def drop_demand_cache_object!(connection)
    [
      'DROP MATERIALIZED VIEW IF EXISTS group_box_ingredient_unit_caches',
      'DROP TABLE IF EXISTS group_box_ingredient_unit_caches'
    ].each do |sql|
      connection.execute(sql)
    rescue ActiveRecord::StatementInvalid => e
      raise unless e.message.include?('is not a table') || e.message.include?('is not a materialized view')
    end
  end

  def ensure_units!
    (BULK_UNITS + PIECE_UNITS).each { |name| Unit.find_or_create_by!(name:) }
  end

  def create_supplier
    FactoryBot.create(:supplier, delivery_time: [0, 12, 24, 48].sample(random: @rng))
  end

  # Stocked, picked (packing-lane stock counts) and packed (skipped) boxes.
  def create_boxes
    Array.new(rand_range(1, 3)) do |index|
      roll = @rng.rand
      FactoryBot.create(
        :box,
        datetime: Time.zone.now + index.days + @rng.rand(0..36).hours,
        status: if roll < 0.15 then :packed
                elsif roll < 0.3 then :picked
                else :stocked
                end
      )
    end
  end

  # A moment relative to the boxes: before the first, exactly at one, between
  # two, or after the last. Release and arrival rules compare with `<=`, so the
  # exact-match case is where an off-by-one would show.
  def random_time_anchor(boxes)
    datetimes = boxes.map(&:datetime).sort
    case @rng.rand(4)
    when 0 then datetimes.first - @rng.rand(1..72).hours
    when 1 then datetimes.sample(random: @rng)
    when 2
      index = @rng.rand([datetimes.size - 1, 1].max)
      later = datetimes[index + 1] || (datetimes[index] + 2.hours)
      datetimes[index] + ((later - datetimes[index]) / 2)
    else datetimes.last + @rng.rand(1..72).hours
    end
  end

  # Stock already moved to a packing lane. Only lanes of picked boxes count
  # towards an article's stock; the rest must be ignored by the planner.
  # Returns the counting quantity per article, worked out independently of
  # Article#packing_lane_stock.
  def create_packing_lane_stocks!(articles, boxes)
    lane = nil
    articles.each_with_object(Hash.new(0)) do |article, active|
      next if @rng.rand < 0.75

      lane ||= FactoryBot.create(:packing_lane)
      box = boxes.sample(random: @rng)
      quantity = @rng.rand(0..30)
      PackingLaneArticleStock.create!(packing_lane: lane, article:, box:, quantity:)
      active[article.id] += quantity if box.picked?
    end
  end

  # Up to three hoards per article, also on articles without stock, of any size
  # (so the hoards can together exceed the stock), due at any point relative
  # to the boxes — including several due at the same box.
  def create_hoards!(articles, boxes)
    articles.each do |article|
      next if @rng.rand < 0.5

      rand_range(1, 3).times do
        Hoard.create!(
          article:,
          quantity: @rng.rand(0..(article.stock.to_i + 30)),
          until: random_time_anchor(boxes)
        )
      end
    end
  end

  # Order lines in every order state. Their coverage begins before, at,
  # between or after the boxes, and deliveries may fall short of or exceed
  # what was ordered. Planned orders that have not begun yet also move the
  # supplier's next possible delivery forward.
  def create_orders!(articles, boxes)
    articles.each do |article|
      next if @rng.rand < 0.6

      rand_range(1, 2).times do
        state = ORDER_STATES.sample(random: @rng)
        coverage_begin = random_time_anchor(boxes)
        order = FactoryBot.create(
          :order, state:, supplier: article.supplier, coverage: (coverage_begin..(coverage_begin + 1.week))
        )
        quantity_ordered = @rng.rand(0..40)
        FactoryBot.create(
          :order_article, order:, article:, quantity_ordered:,
                          quantity_delivered: random_quantity_delivered(state, quantity_ordered)
        )
      end
    end
  end

  def random_quantity_delivered(state, quantity_ordered)
    return 0 unless %i[delivered stored].include?(state)

    case @rng.rand(3)
    when 0 then quantity_ordered
    when 1 then @rng.rand(0..quantity_ordered)
    else quantity_ordered + @rng.rand(1..10)
    end
  end

  # Some ingredients are sold both loose (g) and in pieces (Stk). Demand is
  # matched to articles by ingredient and unit.
  def create_articles(ingredients, suppliers)
    ingredients.flat_map do |ingredient|
      packing_types = @rng.rand < 0.3 ? PACKING_TYPES : [PACKING_TYPES.sample(random: @rng)]
      packing_types.flat_map { create_article_family(ingredient, suppliers, it) }
    end
  end

  def create_article_family(ingredient, suppliers, packing_type)
    unit = packing_type == :bulk ? BULK_UNITS.sample(random: @rng) : PIECE_UNITS.sample(random: @rng)
    Array.new(rand_range(1, 3)) do |priority|
      FactoryBot.create(
        :article,
        ingredient:,
        supplier: suppliers.sample(random: @rng),
        packing_type:,
        unit:,
        quantity: packing_type == :bulk ? 1 : PACKAGE_SIZES.sample(random: @rng),
        stock: @rng.rand(0..120),
        priority:,
        order_limit: @rng.rand < 0.3 ? nil : @rng.rand(20..200)
      )
    end
  end

  def create_demands(groups, boxes, ingredients, articles)
    units_by_ingredient = articles.group_by(&:ingredient_id).transform_values { it.map(&:unit).uniq }
    demands = []
    groups.each do |group|
      boxes.each do |box|
        ingredients.each do |ingredient|
          next if @rng.rand < 0.25

          unit = @rng.rand < 0.05 ? UNSOLD_UNIT : units_by_ingredient.fetch(ingredient.id).sample(random: @rng)
          demand = {
            group_id: group.id,
            box_id: box.id,
            ingredient_id: ingredient.id,
            unit:,
            quantity: random_demand_quantity
          }
          insert_demand(**demand)
          demands << demand
        end
      end
    end
    demands
  end

  # Real demand is recipe quantities (two decimals) times hunger factors, so it
  # is usually fractional. Mostly two-decimal values, some whole numbers.
  def random_demand_quantity
    whole = @rng.rand(1..150)
    return whole if @rng.rand < 0.3

    BigDecimal(whole) - (BigDecimal(@rng.rand(1..99)) / 100)
  end

  def insert_demand(group_id:, box_id:, ingredient_id:, unit:, quantity:)
    sql = ActiveRecord::Base.sanitize_sql_array(
      ['INSERT INTO group_box_ingredient_unit_caches ' \
       '(group_id, box_id, ingredient_id, unit, quantity) VALUES (?, ?, ?, ?, ?)',
       group_id, box_id, ingredient_id, unit, quantity]
    )
    ActiveRecord::Base.connection.execute(sql)
  end

  def rand_range(min, max)
    @rng.rand(min..max)
  end

  def fail_invariant!(scenario, name, detail)
    prefix = if scenario
               "trial #{scenario.trial} (seed #{scenario.seed}) [#{name}]"
             else
               "[#{name}]"
             end
    raise InvariantViolation, "#{prefix}: #{detail}"
  end

  def report
    @out.puts
    if @failures.empty?
      @out.puts "OK — #{@trials} trials, 0 invariant violations"
    else
      @out.puts "FAILED — #{@failures.size}/#{@trials} trials violated invariants:"
      @failures.each { @out.puts "  trial #{it[:trial]}: #{it[:message]}" }
    end
  end

  # Independent model of one article's stock, incoming orders and hoards over
  # the boxes the planner processes, written from the domain rules rather than
  # from ArticleAvailabilityPlanner:
  #
  # - Hoards block min(stock, sum of hoard quantities) of the stock.
  # - An order line becomes available once its order's coverage has begun. An
  #   ordered order brings what was ordered and a delivered one what was
  #   delivered; planned and canceled orders bring nothing, and a stored
  #   order's goods are already part of the article's stock.
  # - A hoard is released at the first processed box at or after its `until`;
  #   hoards still pending after the last box are released at the end.
  #   Hoards due together are released in (until, id) order.
  # - A hoard needs backup for its whole lifetime, from now until its date. It
  #   is covered from blocked stock first, then from delivered goods still on
  #   hand that no earlier hoard has counted: all lifetimes overlap, so a
  #   delivered unit backs at most one hoard.
  # - Hoards still pending after the last box also count deliveries arriving
  #   before their own date.
  # - The caller passes only processed boxes: nothing arrives or is released
  #   at a packed box.
  class ArticleLifecycleSimulator
    attr_reader :expected_missing

    def initialize(total_stock:, hoards:, order_articles:)
      @pending_hoards = hoards.sort_by { [it.until, it.id] }
      @pending_orders = order_articles.dup
      @current_hoard = [total_stock, hoards.sum(&:quantity)].min
      @available_stock = total_stock - @current_hoard
      @available_ordered = 0
      @arrived_ordered = 0
      @counted_for_hoards = 0
      @expected_missing = {}
    end

    def process_box(datetime, abor: nil)
      advance_orders(datetime)
      advance_hoards(datetime)
      return unless abor

      consume_stock!(abor.stock.to_d)
      consume_ordered!(abor.ordered.to_d)
    end

    def finish_remaining_hoards
      @pending_hoards.each do |hoard|
        advance_orders(hoard.until)
        release_hoard(hoard)
      end
      @pending_hoards = []
    end

    private

    def advance_orders(datetime)
      arrived, @pending_orders = @pending_orders.partition { it.order.coverage_begin <= datetime }
      quantity = arrived.sum { incoming_quantity(it) }
      @available_ordered += quantity
      @arrived_ordered += quantity
    end

    def incoming_quantity(order_article)
      case order_article.order.state
      when 'ordered' then order_article.quantity_ordered.to_d
      when 'delivered' then order_article.quantity_delivered.to_d
      else 0
      end
    end

    def advance_hoards(datetime)
      due, @pending_hoards = @pending_hoards.partition { it.until <= datetime }
      due.each { release_hoard(it) }
    end

    def release_hoard(hoard)
      from_stock = [@current_hoard, hoard.quantity].min
      @current_hoard -= from_stock
      @available_stock += from_stock
      never_counted = @arrived_ordered - @counted_for_hoards
      from_incoming = [@available_ordered, never_counted, hoard.quantity - from_stock].min
      @counted_for_hoards += from_incoming
      @expected_missing[hoard.id] = hoard.quantity - from_stock - from_incoming
    end

    def consume_stock!(quantity)
      raise HoardInvariantError, "stock draw #{quantity} exceeds #{@available_stock}" if quantity > @available_stock

      @available_stock -= quantity
    end

    def consume_ordered!(quantity)
      if quantity > @available_ordered
        raise HoardInvariantError, "ordered draw #{quantity} exceeds #{@available_ordered}"
      end

      @available_ordered -= quantity
    end
  end

  class HoardInvariantError < StandardError; end
end
