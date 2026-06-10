# Turns per-group ingredient demand (GroupBoxIngredientUnitCache) into concrete
# packing rows (GroupBoxArticle), order requirements (ArticleBoxOrderRequirement),
# and shortfalls (MissingIngredient).
#
# Call graph:
#   run
#     load_data
#     process_ingredient_unit          — one ingredient+unit across all boxes
#       process_ingredient_unit_in_box — reset article planners for this box
#         process_with_fair_sharing    — proportional split when stock is scarce
#           fulfill_demand             — immediate share per group
#           allocate_shared_shortfall    — fairly shared leftover immediate capacity
#           allocate_sequential_shortfall — orderable capacity in group order
#           exhaust_remaining_capacity   — spend leftover pools when demand stays unmet
#         fulfill_demand               — single-group path
#           reserve_for_demand
#             allocate_units             — piece packages first, then bulk
#       add_order_requirements
#     update_plan
#     finish_articles                  — release hoard bookkeeping on articles
class ArticlePackingPlanner
  include Calculatable

  MODEL_DEPENDENCIES = [Article, Box, Hoard, Order, OrderArticle, PackingLane, PackingLaneArticleStock, Supplier].freeze
  CALCULATION_DEPENDENCIES = [GroupBoxIngredientUnitCache].freeze

  def self.do_calculate
    new.run
  end

  def initialize
    @missing_ingredients = []
    @group_box_articles = []
    @article_box_order_requirements = []
  end

  # Rebuilds the full packing plan inside one transaction.
  def run
    ActiveRecord::Base.transaction do
      load_data
      @demands.each do |ingredient_unit, ingredient_entries|
        process_ingredient_unit(ingredient_unit, ingredient_entries)
      end
      update_plan
      finish_articles
    end
  end

  private

  # articles — ArticleAvailabilityPlanner wrappers keyed by ingredient_unit
  # demands  — GroupBoxIngredientUnitCache rows keyed by ingredient_unit
  def load_data
    @all_articles = Article.all.group_by(&:ingredient_unit).transform_values do |articles|
      articles.map { ArticleAvailabilityPlanner.new(it) }
    end
    @demands = GroupBoxIngredientUnitCache
               .includes(:ingredient, :box)
               .where.not(box: nil)
               .all
               .group_by(&:ingredient_unit)
  end

  # entries — demand rows sharing the same ingredient and unit
  def process_ingredient_unit(ingredient_unit, ingredient_entries)
    articles = @all_articles.fetch(ingredient_unit, [])
    ingredient_entries.sort_by { it.box.datetime }.group_by(&:box).each do |box, entries|
      process_ingredient_unit_in_box(box, entries, articles)
    end
  end

  # entries — all groups needing this ingredient in the same box
  def process_ingredient_unit_in_box(box, entries, articles)
    return if box.packed?

    articles.each { it.start_processing box }
    if needs_fair_sharing?(entries, articles)
      process_with_fair_sharing(entries, articles)
    else
      entries.each { fulfill_single_group_demand(it, articles) }
    end
    add_order_requirements(box, articles)
  end

  # Fair sharing applies only when several groups compete for less stock than
  # the combined demand (orders may still cover the gap afterward).
  def needs_fair_sharing?(entries, articles)
    return false unless entries.many?

    entries.sum(&:quantity) > articles.sum(&:total_coverable_units)
  end

  # Three-step split: proportional immediate stock/orders, fairly shared leftover
  # immediate capacity, then sequential orderable capacity before recording gaps.
  def process_with_fair_sharing(entries, articles)
    total_demand = entries.sum(&:quantity)
    immediate_shares = proportional_shares(entries, articles.sum(&:immediate_units), total_demand)
    covered_by_entry = entries.index_with { 0 }

    entries.each do |entry|
      covered_by_entry[entry] += fulfill_demand(entry, articles, immediate_shares.fetch(entry), only: :immediate)
    end

    allocate_shared_shortfall!(entries, articles, covered_by_entry, only: :immediate)
    allocate_sequential_shortfall!(entries, articles, covered_by_entry, only: :orderable)
    exhaust_remaining_capacity!(entries, articles, covered_by_entry)
    record_unmet_shortfalls!(entries, covered_by_entry)
  end

  def fulfill_single_group_demand(entry, articles)
    covered_by_entry = { entry => reserve_for_demand(entry, articles, entry.quantity) }
    exhaust_remaining_capacity!([entry], articles, covered_by_entry)
    record_unmet_shortfalls!([entry], covered_by_entry)
  end

  def allocate_shared_shortfall!(entries, articles, covered_by_entry, only:)
    shortfalls = current_shortfalls(entries, covered_by_entry)
    return if shortfalls.empty?

    pool_units = remaining_capacity_units(articles, only:)
    return if pool_units.zero?

    shares = proportional_shares(
      shortfalls.map(&:first),
      pool_units,
      shortfalls.sum { |_, shortfall| shortfall },
      weight: ->(entry) { entry_shortfall(entry, covered_by_entry) }
    )

    shortfalls.each do |entry, shortfall|
      allowance = [shares.fetch(entry), shortfall].min
      covered_by_entry[entry] += fulfill_demand(entry, articles, allowance, only:)
    end
  end

  def allocate_sequential_shortfall!(entries, articles, covered_by_entry, only:)
    current_shortfalls(entries, covered_by_entry).each do |entry, shortfall|
      covered_by_entry[entry] += fulfill_demand(entry, articles, shortfall, only:)
    end
  end

  def record_unmet_shortfalls!(entries, covered_by_entry)
    entries.each do |entry|
      shortfall = entry_shortfall(entry, covered_by_entry)
      add_missing_ingredient(entry, shortfall) if shortfall.positive?
    end
  end

  # When demand is still unmet, assign every remaining package to groups with
  # shortfall (overshoot is fine) so stock and order limits are fully spent.
  def exhaust_remaining_capacity!(entries, articles, covered_by_entry)
    return if current_shortfalls(entries, covered_by_entry).empty?

    %i[immediate orderable].each do |only|
      loop do
        pool_units = remaining_capacity_units(articles, only:)
        break if pool_units.zero?

        shortfalls = current_shortfalls(entries, covered_by_entry)
        break if shortfalls.empty?

        shares = proportional_shares(
          shortfalls.map(&:first),
          pool_units,
          shortfalls.sum { |_, shortfall| shortfall },
          weight: ->(entry) { entry_shortfall(entry, covered_by_entry) }
        )
        progress = false
        shortfalls.each do |entry, _shortfall|
          allowance = shares.fetch(entry)
          next if allowance.zero?

          spent = fulfill_demand(entry, articles, allowance, only:)
          covered_by_entry[entry] += spent
          progress = true if spent.positive?
        end
        break unless progress
      end
    end
  end

  def current_shortfalls(entries, covered_by_entry)
    entries.filter_map do |entry|
      shortfall = entry_shortfall(entry, covered_by_entry)
      [entry, shortfall] if shortfall.positive?
    end
  end

  def entry_shortfall(entry, covered_by_entry)
    entry.quantity - covered_by_entry.fetch(entry)
  end

  def remaining_capacity_units(articles, only:)
    articles.sum do |article|
      packages =
        case only
        when :immediate then article.immediate_packages
        when :orderable then article.orderable_packages
        else article.max_packages
        end
      next 0 if packages == Float::INFINITY

      packages * article.quantity
    end
  end

  # Largest-remainder allocation: floor shares, then distribute leftover units
  # to entries with the highest fractional parts (group_id breaks ties).
  def proportional_shares(entries, total_available, total_weight, weight: nil)
    return entries.index_with { 0 } unless total_weight.positive?

    weight_for = weight || ->(entry) { entry.quantity }
    allocations = entries.map do |entry|
      exact_share = Rational(total_available) * weight_for.call(entry) / total_weight
      { entry:, floor: exact_share.floor, fraction: exact_share - exact_share.floor }
    end
    remainder = total_available - allocations.sum { it[:floor] }
    allocations.sort_by { [-it[:fraction], it[:entry].group_id] }
               .first(remainder)
               .each { it[:floor] += 1 }
    allocations.to_h { [it[:entry], it[:floor]] }
  end

  # only — passed through to ArticleAvailabilityPlanner#reserve
  # Returns units covered by allocate_units.
  def fulfill_demand(entry, articles, required, only: nil)
    reserve_for_demand(entry, articles, required, only:)
  end

  # Shared reservation path for fulfill_demand and fair-sharing shortfall passes.
  def reserve_for_demand(entry, articles, units, only: nil, record_missing: false)
    return 0 unless units.positive?

    piece_articles, bulk_articles = partition_articles(articles)
    required_articles = Hash.new(0)
    covered = allocate_units(piece_articles, bulk_articles, units, required_articles, only:)

    remaining = units - covered
    add_missing_ingredient(entry, remaining) if remaining.positive? && record_missing
    add_required_articles(entry, required_articles)
    covered
  end

  def partition_articles(articles)
    articles.partition(&:piece?)
  end

  # Piece-sized packages are optimised globally; bulk articles fill the rest
  # greedily in article order. A second piece pass covers sub-package gaps
  # left by bulk divmod.
  def allocate_units(piece_articles, bulk_articles, required_units, required_articles, only: nil)
    covered = reserve_piece_packages(piece_articles, required_units, required_articles, only:)
    still_needed = required_units - covered
    if still_needed.positive?
      covered += reserve_bulk_packages(bulk_articles, still_needed, required_articles, only:)
      still_needed = required_units - covered
      covered += reserve_piece_packages(piece_articles, still_needed, required_articles, only:) if still_needed.positive?
    end
    covered
  end

  def reserve_piece_packages(articles, required_units, required_articles, only: nil)
    return 0 if required_units <= 0 || articles.empty?

    articles_by_id = articles.index_by(&:id)
    covered = 0
    ArticlePiecePackageSelector.new(required_units, articles, only:).select.each do |article_id, package_count|
      article = articles_by_id.fetch(article_id)
      quantity_reserved = article.reserve(package_count, only:)
      required_articles[article_id] += quantity_reserved
      covered += quantity_reserved * article.quantity
    end
    covered
  end

  def reserve_bulk_packages(articles, required_units, required_articles, only: nil)
    return 0 if required_units <= 0

    remaining = required_units
    articles.each do |article|
      quantity_fit, = remaining.divmod(article.quantity)
      quantity_reserved = article.reserve(quantity_fit, only:)
      required_articles[article.id] += quantity_reserved
      remaining -= quantity_reserved * article.quantity
    end
    required_units - remaining
  end

  # Keeps GroupBoxArticle rows for packed boxes; replaces everything else.
  def update_plan
    GroupBoxArticle.where.not(box: Box.packed).delete_all
    @group_box_articles.any? && GroupBoxArticle.insert_all(
      @group_box_articles, unique_by: %i[group_id box_id article_id]
    )
    ArticleBoxOrderRequirement.delete_all
    @article_box_order_requirements.any? && ArticleBoxOrderRequirement.insert_all(
      @article_box_order_requirements, unique_by: %i[article_id box_id]
    )
    MissingIngredient.delete_all
    @missing_ingredients.any? && MissingIngredient.insert_all(
      @missing_ingredients, unique_by: %i[group_id box_id ingredient_id unit]
    )
  end

  # Snapshots per-article reservation totals after each box is processed.
  def add_order_requirements(box, articles)
    @article_box_order_requirements += articles.select(&:order_requirements?).map do |article|
      {
        article_id: article.id,
        box_id: box.id,
        quantity: article.order_requirement,
        stock: article.stock,
        ordered: article.ordered
      }
    end
  end

  def add_missing_ingredient(entry, quantity)
    @missing_ingredients << {
      group_id: entry.group_id,
      box_id: entry.box_id,
      ingredient_id: entry.ingredient_id,
      unit: entry.unit,
      quantity: quantity
    }
  end

  # Merges into an existing row when fair sharing runs multiple passes for
  # the same group/box/article.
  def add_required_articles(entry, required_articles)
    required_articles.each do |article_id, quantity|
      next if quantity.zero?

      existing = @group_box_articles.find do |row|
        row[:group_id] == entry.group_id && row[:box_id] == entry.box_id && row[:article_id] == article_id
      end
      if existing
        existing[:quantity] += quantity
      else
        @group_box_articles << {
          group_id: entry.group_id,
          box_id: entry.box_id,
          article_id: article_id,
          quantity: quantity
        }
      end
    end
  end

  # Runs hoard release logic left over after the last box for each article.
  def finish_articles
    @all_articles.each_value { it.each(&:finish) }
  end
end
