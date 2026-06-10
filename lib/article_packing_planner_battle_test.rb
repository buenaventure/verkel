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
#
# Run via: RAILS_ENV=test bin/rails runner script/battle_test_article_packing_planner.rb
class ArticlePackingPlannerBattleTest
  class InvariantViolation < StandardError; end

  PACKING_TYPES = %i[bulk piece].freeze
  BULK_UNITS = %w[g].freeze
  PIECE_UNITS = %w[Stk].freeze
  PACKAGE_SIZES = [1, 5, 10, 20, 30, 100].freeze

  Scenario = Data.define(
    :trial,
    :seed,
    :demands,
    :articles_by_id,
    :initial_stock,
    :initial_order_limits,
    :packed_box_snapshots,
    :suppliers_by_id
  )

  def self.run(trials: 25, seed: Random.new_seed, verbose: false)
    new(trials:, seed:, verbose:).run
  end

  def initialize(trials:, seed:, verbose:)
    @trials = trials
    @rng = Random.new(seed)
    @seed = seed
    @verbose = verbose
    @failures = []
  end

  def run
    puts "ArticlePackingPlanner battle test — #{@trials} trials, seed #{@seed}"
    @trials.times { |trial| run_trial(trial) }
    report
  end

  private

  def run_trial(trial)
    ActiveRecord::Base.transaction do
      scenario = build_scenario(trial)
      print '.' if @verbose
      planner_run(scenario)
      verify_invariants!(scenario)
      verify_idempotency!(scenario)
      raise ActiveRecord::Rollback
    end
  rescue InvariantViolation => e
    @failures << { trial:, message: e.message }
    print 'F' if @verbose
  end

  def build_scenario(trial)
    clear_planner_outputs!
    fake_demand_cache!
    ensure_units!

    suppliers = Array.new(rand_range(1, 2)) { create_supplier }
    ingredients = Array.new(rand_range(2, 4)) { FactoryBot.create(:ingredient) }
    boxes = create_boxes
    packed_boxes = boxes.select(&:packed?)
    articles = create_articles(ingredients, suppliers)
    groups = Array.new(rand_range(2, 6)) { FactoryBot.create(:group) }
    demands = create_demands(groups, boxes, ingredients)
    seed_packed_box_plans!(packed_boxes, groups, articles)
    demands.concat(record_seeded_packed_demands(packed_boxes, groups, articles))
    packed_snapshots = snapshot_packed_box_articles(packed_boxes)

    Scenario.new(
      trial:,
      seed: @seed,
      demands:,
      articles_by_id: articles.index_by(&:id),
      initial_stock: articles.to_h { |article| [article.id, article.stock + article.packing_lane_stock] },
      initial_order_limits: articles.to_h { |article| [article.id, article.current_order_limit] },
      packed_box_snapshots: packed_snapshots,
      suppliers_by_id: suppliers.index_by(&:id)
    )
  end

  def planner_run(_scenario)
    ArticlePackingPlanner.new.run
  end

  def verify_invariants!(scenario)
    check_demand_fulfillment!(scenario)
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
      )&.quantity.to_d || 0
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
    packed_box_ids = Box.where(status: :packed).pluck(:id).to_set
    GroupBoxArticle.includes(:article).find_each do |gba|
      next if packed_box_ids.include?(gba.box_id)

      article = gba.article
      demand = scenario.demands.find do |entry|
        entry[:group_id] == gba.group_id &&
          entry[:box_id] == gba.box_id &&
          entry[:ingredient_id] == article.ingredient_id &&
          entry[:unit] == article.unit
      end
      next if demand

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

    packed_box_ids = Box.where(status: :packed).pluck(:id).to_set
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
      current = gba&.quantity.to_d || 0
      next if current == quantity.to_d

      fail_invariant!(
        scenario,
        'packed_boxes_preserved',
        "packed box plan changed for #{key.inspect}: was #{quantity}, now #{current}"
      )
    end
  end

  def check_no_demand_leak_into_packed_boxes!(scenario)
    packed_box_ids = Box.where(status: :packed).pluck(:id)
    return if packed_box_ids.empty?

    if MissingIngredient.where(box_id: packed_box_ids).exists?
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

  def record_seeded_packed_demands(packed_boxes, _groups, _articles)
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
    connection.execute('DROP MATERIALIZED VIEW IF EXISTS group_box_ingredient_unit_caches')
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

  def ensure_units!
    (BULK_UNITS + PIECE_UNITS).each { |name| Unit.find_or_create_by!(name:) }
  end

  def create_supplier
    FactoryBot.create(:supplier, delivery_time: [0, 12, 24, 48].sample(random: @rng))
  end

  def create_boxes
    count = rand_range(1, 3)
    Array.new(count) do |index|
      packed = @rng.rand < 0.15
      FactoryBot.create(
        :box,
        datetime: Time.zone.now + index.days + @rng.rand(0..36).hours,
        status: packed ? :packed : :stocked
      )
    end
  end

  def create_articles(ingredients, suppliers)
    ingredients.flat_map do |ingredient|
      packing_type = PACKING_TYPES.sample(random: @rng)
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
  end

  def create_demands(groups, boxes, ingredients)
    demands = []
    groups.each do |group|
      boxes.each do |box|
        ingredients.each do |ingredient|
          next if @rng.rand < 0.25

          article = Article.where(ingredient:).first
          quantity = @rng.rand(1..150)
          insert_demand(
            group_id: group.id,
            box_id: box.id,
            ingredient_id: ingredient.id,
            unit: article.unit,
            quantity:
          )
          demands << {
            group_id: group.id,
            box_id: box.id,
            ingredient_id: ingredient.id,
            unit: article.unit,
            quantity:
          }
        end
      end
    end
    demands
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
    puts
    if @failures.empty?
      puts "OK — #{@trials} trials, 0 invariant violations"
      return
    end

    puts "FAILED — #{@failures.size}/#{@trials} trials violated invariants:"
    @failures.each { |failure| puts "  trial #{failure[:trial]}: #{failure[:message]}" }
    exit 1
  end
end
