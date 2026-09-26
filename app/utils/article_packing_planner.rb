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
#           reserve_for_demand           — immediate share per group
#           allocate_by_shortfall!       — leftover capacity, weighted by shortfall
#           allocate_sequential_shortfall! — orderable capacity in group order
#           exhaust_remaining_capacity!  — spend leftover pools when demand stays unmet
#           record_unmet_shortfalls!
#         fulfill_single_group_demand  — single-group path
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
    # Keyed by [group_id, box_id, article_id] so repeated fair-sharing passes
    # merge into one row; insertion order is the order rows are written.
    @group_box_articles = {}
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
    immediate_shares = proportional_shares(entries.map { [it, it.quantity] }, articles.sum(&:immediate_units))
    covered_by_entry = entries.index_with { 0 }

    entries.each do |entry|
      covered_by_entry[entry] +=
        reserve_for_demand(entry, articles, immediate_shares.fetch(entry), only: :immediate)
    end

    allocate_by_shortfall!(entries, articles, covered_by_entry, only: :immediate)
    allocate_sequential_shortfall!(entries, articles, covered_by_entry, only: :orderable)
    exhaust_remaining_capacity!(entries, articles, covered_by_entry)
    record_unmet_shortfalls!(entries, covered_by_entry)
  end

  def fulfill_single_group_demand(entry, articles)
    covered_by_entry = { entry => reserve_for_demand(entry, articles, entry.quantity) }
    exhaust_remaining_capacity!([entry], articles, covered_by_entry)
    record_unmet_shortfalls!([entry], covered_by_entry)
  end

  # Hands out the remaining capacity of one pool in proportion to each group's
  # shortfall, never more than a group is short; reserving whole packages may
  # still overshoot by less than one package. Returns the units reserved.
  def allocate_by_shortfall!(entries, articles, covered_by_entry, only:)
    shortfalls = current_shortfalls(entries, covered_by_entry)
    return 0 if shortfalls.empty?

    pool_units = remaining_capacity_units(articles, only:)
    return 0 if pool_units.zero?

    shares = proportional_shares(shortfalls, pool_units)
    shortfalls.sum do |entry, shortfall|
      allowance = [shares.fetch(entry), shortfall].min
      next 0 unless allowance.positive?

      spent = reserve_for_demand(entry, articles, allowance, only:)
      covered_by_entry[entry] += spent
      spent
    end
  end

  def allocate_sequential_shortfall!(entries, articles, covered_by_entry, only:)
    current_shortfalls(entries, covered_by_entry).each do |entry, shortfall|
      covered_by_entry[entry] += reserve_for_demand(entry, articles, shortfall, only:)
    end
  end

  def record_unmet_shortfalls!(entries, covered_by_entry)
    entries.each do |entry|
      shortfall = entry_shortfall(entry, covered_by_entry)
      add_missing_ingredient(entry, shortfall) if shortfall.positive?
    end
  end

  # When demand is still unmet, keep handing remaining packages to groups that
  # are short until they are covered or stock and order limits are spent.
  def exhaust_remaining_capacity!(entries, articles, covered_by_entry)
    %i[immediate orderable].each do |only|
      loop do
        spent = allocate_by_shortfall!(entries, articles, covered_by_entry, only:)
        break unless spent.positive?
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
      packages = article.packages_for(only)
      next 0 if packages == Float::INFINITY

      packages * article.quantity
    end
  end

  # Largest-remainder allocation over [entry, weight] pairs: floor each share,
  # then hand the leftover units to the largest remainders (group_id breaks ties).
  def proportional_shares(weighted_entries, total_available)
    total_weight = weighted_entries.sum { it[1] }
    return weighted_entries.to_h { [it[0], 0] } unless total_weight.positive?

    allocations = floor_shares(weighted_entries, total_available, total_weight)
    hand_out_leftover!(allocations, total_available)
    allocations.to_h { [it[:entry], it[:share]] }
  end

  def floor_shares(weighted_entries, total_available, total_weight)
    weighted_entries.map do |entry, weight|
      share, remainder = (total_available * weight).divmod(total_weight)
      { entry:, share: share.to_i, remainder: }
    end
  end

  # Gives the units lost to flooring to the largest remainders, one each.
  def hand_out_leftover!(allocations, total_available)
    leftover = (total_available - allocations.sum { it[:share] }).to_i
    allocations.sort_by { [-it[:remainder], it[:entry].group_id] }.first(leftover).each { it[:share] += 1 }
  end

  # Reserves up to `units` for one group and records the packages it gets.
  # `only` is passed through to ArticleAvailabilityPlanner#reserve.
  # Returns the units actually covered.
  def reserve_for_demand(entry, articles, units, only: nil)
    return 0 unless units.positive?

    piece_articles, bulk_articles = articles.partition(&:piece?)
    required_articles = Hash.new(0)
    covered = allocate_units(piece_articles, bulk_articles, units, required_articles, only:)
    add_required_articles(entry, required_articles)
    covered
  end

  # Piece-sized packages are optimised globally; bulk articles fill the rest
  # greedily in article order. When the piece selector cannot cover the demand
  # it has already used every piece package available in this mode, so there is
  # nothing left for pieces to add after the bulk pass.
  def allocate_units(piece_articles, bulk_articles, required_units, required_articles, only: nil)
    covered = reserve_piece_packages(piece_articles, required_units, required_articles, only:)
    covered + reserve_bulk_packages(bulk_articles, required_units - covered, required_articles, only:)
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

  # Rounds up to whole packages, so a fractional demand (10.5 g) is covered
  # (11 g) rather than left a fraction short.
  def reserve_bulk_packages(articles, required_units, required_articles, only: nil)
    return 0 if required_units <= 0

    remaining = required_units
    articles.each do |article|
      break unless remaining.positive?

      quantity_reserved = article.reserve((remaining / article.quantity).ceil, only:)
      required_articles[article.id] += quantity_reserved
      remaining -= quantity_reserved * article.quantity
    end
    required_units - remaining
  end

  # Keeps GroupBoxArticle rows for packed boxes; replaces everything else.
  def update_plan
    GroupBoxArticle.where.not(box: Box.packed).delete_all
    group_box_article_rows = @group_box_articles.values
    group_box_article_rows.any? && GroupBoxArticle.insert_all(
      group_box_article_rows, unique_by: %i[group_id box_id article_id]
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

      row = @group_box_articles[[entry.group_id, entry.box_id, article_id]] ||= {
        group_id: entry.group_id,
        box_id: entry.box_id,
        article_id: article_id,
        quantity: 0
      }
      row[:quantity] += quantity
    end
  end

  # Runs hoard release logic left over after the last box for each article.
  def finish_articles
    @all_articles.each_value { it.each(&:finish) }
  end
end
