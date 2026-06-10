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
#           reserve_for_demand         — immediate pass, then orderable remainder
#         fulfill_demand               — single-group path
#           reserve_for_demand
#             allocate_units             — piece packages first, then bulk
#             handle_remaining           — whole-package top-up (full mode only)
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
      entries.each { fulfill_demand(it, articles, it.quantity) }
    end
    add_order_requirements(box, articles)
  end

  # Fair sharing applies only when several groups compete for less stock than
  # the combined demand (orders may still cover the gap afterward).
  def needs_fair_sharing?(entries, articles)
    return false unless entries.many?

    entries.sum(&:quantity) > articles.sum(&:total_coverable_units)
  end

  # Two-pass split: immediate stock/orders by proportional share, then
  # orderable capacity for whatever each group still lacks.
  def process_with_fair_sharing(entries, articles)
    total_demand = entries.sum(&:quantity)
    immediate_shares = proportional_shares(entries, articles.sum(&:immediate_units), total_demand)

    entries.each do |entry|
      covered = fulfill_demand(entry, articles, immediate_shares.fetch(entry), only: :immediate)
      fulfill_remainder(entry, articles, entry.quantity - covered) if entry.quantity > covered
    end
  end

  # Largest-remainder allocation: floor shares, then distribute leftover units
  # to entries with the highest fractional parts (group_id breaks ties).
  def proportional_shares(entries, total_available, total_demand)
    return entries.index_with { 0 } unless total_demand.positive?

    allocations = entries.map do |entry|
      exact_share = Rational(total_available) * entry.quantity / total_demand
      { entry:, floor: exact_share.floor, fraction: exact_share - exact_share.floor }
    end
    remainder = total_available - allocations.sum { it[:floor] }
    allocations.sort_by { [-it[:fraction], it[:entry].group_id] }
               .first(remainder)
               .each { it[:floor] += 1 }
    allocations.to_h { [it[:entry], it[:floor]] }
  end

  # only — passed through to ArticleAvailabilityPlanner#reserve
  # Returns units covered by allocate_units (excludes handle_remaining top-up).
  def fulfill_demand(entry, articles, required, only: nil)
    reserve_for_demand(entry, articles, required, only:, top_up: only.nil?)
  end

  # Second fair-sharing pass: may only draw from orderable supplier capacity.
  def fulfill_remainder(entry, articles, remaining)
    reserve_for_demand(entry, articles, remaining, only: :orderable, record_missing: true)
  end

  # Shared reservation path for fulfill_demand and fulfill_remainder.
  def reserve_for_demand(entry, articles, units, only: nil, top_up: false, record_missing: false)
    return 0 unless units.positive?

    piece_articles, bulk_articles = partition_articles(articles)
    required_articles = Hash.new(0)
    covered = allocate_units(piece_articles, bulk_articles, units, required_articles, only:)

    remaining = units - covered
    handle_remaining(remaining, articles, required_articles, entry) if top_up && remaining.positive?

    add_missing_ingredient(entry, remaining) if record_missing && remaining.positive?
    add_required_articles(entry, required_articles)
    covered
  end

  def partition_articles(articles)
    articles.partition(&:piece?)
  end

  # Piece-sized packages are optimised globally; bulk articles fill the rest
  # greedily in article order.
  def allocate_units(piece_articles, bulk_articles, required_units, required_articles, only: nil)
    covered = reserve_piece_packages(piece_articles, required_units, required_articles, only:)
    still_needed = required_units - covered
    return covered unless still_needed.positive?

    covered + reserve_bulk_packages(bulk_articles, still_needed, required_articles, only:)
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

  # After fractional bulk/piece allocation, try one more optimised piece pass
  # then reserve a single whole package of the smallest available article.
  def handle_remaining(quantity, articles, required_articles, entry)
    return unless quantity.positive?

    piece_articles, = partition_articles(articles)
    if piece_articles.any?
      covered = reserve_piece_packages(piece_articles, quantity, required_articles)
      quantity -= covered
    end

    if quantity.positive? && (article = select_filling_article(articles))
      required_articles[article.id] += 1
      reserved = article.reserve(1)
      raise 'expected one package to be reserved' unless reserved == 1

      quantity -= reserved * article.quantity
    end

    add_missing_ingredient(entry, quantity) if quantity.positive?
  end

  # Smallest package first; priority breaks ties (lower number wins).
  def select_filling_article(articles)
    articles.select(&:available?).min_by { [it.quantity, it.priority] }
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
