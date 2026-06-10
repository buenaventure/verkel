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

  def process_ingredient_unit(ingredient_unit, ingredient_entries)
    articles = @all_articles.fetch(ingredient_unit, [])
    ingredient_entries.sort_by { it.box.datetime }.group_by(&:box).each do |box, entries|
      process_ingredient_unit_in_box(box, entries, articles)
    end
  end

  def process_ingredient_unit_in_box(box, entries, articles)
    return if box.packed? # skip boxes which are done

    articles.each { it.start_processing box }
    if needs_fair_sharing?(entries, articles)
      process_with_fair_sharing(entries, articles)
    else
      entries.each do |entry|
        process_ingredient_unit_in_group_box(entry, articles)
      end
    end
    add_order_requirements(box, articles)
  end

  def needs_fair_sharing?(entries, articles)
    return false unless entries.many?

    total_demand = entries.sum(&:quantity)
    total_coverable = articles.sum(&:total_coverable_units)
    total_coverable < total_demand
  end

  def process_with_fair_sharing(entries, articles)
    total_demand = entries.sum(&:quantity)
    total_immediate = articles.sum(&:immediate_units)
    immediate_shares = proportional_shares(entries, total_immediate, total_demand)

    entries.each do |entry|
      immediate_share = immediate_shares.fetch(entry)
      covered = fulfill_demand(entry, articles, immediate_share, immediate_only: true)
      remaining = entry.quantity - covered
      fulfill_remainder(entry, articles, remaining) if remaining.positive?
    end
  end

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

  def process_ingredient_unit_in_group_box(entry, articles)
    fulfill_demand(entry, articles, entry.quantity)
  end

  def fulfill_demand(entry, articles, required, immediate_only: false)
    return 0 unless required.positive?

    piece_articles, bulk_articles = articles.partition(&:piece?)
    required_articles = Hash.new(0)
    covered = allocate_units(
      piece_articles,
      bulk_articles,
      required,
      required_articles,
      immediate_only:,
      orderable_only: false
    )
    remaining = required - covered

    handle_remaining(remaining, articles, required_articles, entry) if !immediate_only && remaining.positive?

    add_required_articles(entry, required_articles)
    covered
  end

  def fulfill_remainder(entry, articles, remaining)
    piece_articles, bulk_articles = articles.partition(&:piece?)
    required_articles = Hash.new(0)
    covered = allocate_units(
      piece_articles,
      bulk_articles,
      remaining,
      required_articles,
      immediate_only: false,
      orderable_only: true
    )
    uncovered = remaining - covered
    add_missing_ingredient(entry, uncovered) if uncovered.positive?
    add_required_articles(entry, required_articles)
  end

  def allocate_units(piece_articles, bulk_articles, required_units, required_articles, immediate_only:, orderable_only:)
    covered = reserve_piece_packages(
      piece_articles,
      required_units,
      required_articles,
      immediate_only:,
      orderable_only:
    )
    still_needed = required_units - covered
    return covered unless still_needed.positive?

    covered + reserve_bulk_packages(
      bulk_articles,
      still_needed,
      required_articles,
      immediate_only:,
      orderable_only:
    )
  end

  def reserve_piece_packages(articles, required_units, required_articles, immediate_only: false, orderable_only: false)
    return 0 if required_units <= 0 || articles.empty?

    package_plan = ArticlePiecePackageSelector.new(
      required_units,
      articles,
      immediate_only:,
      orderable_only:
    ).select
    covered = 0
    package_plan.each do |article_id, package_count|
      article = articles.find { it.id == article_id }
      quantity_reserved = article.reserve(package_count, immediate_only:, orderable_only:)
      required_articles[article_id] += quantity_reserved
      covered += quantity_reserved * article.quantity
    end
    covered
  end

  def reserve_bulk_packages(articles, required_units, required_articles, immediate_only: false, orderable_only: false)
    return 0 if required_units <= 0

    remaining = required_units
    articles.each do |article|
      quantity_fit, = remaining.divmod(article.quantity)
      quantity_reserved = article.reserve(quantity_fit, immediate_only:, orderable_only:)
      required_articles[article.id] += quantity_reserved
      remaining -= quantity_reserved * article.quantity
    end
    required_units - remaining
  end

  def handle_remaining(quantity, articles, required_articles, entry)
    return unless quantity.positive?

    piece_articles = articles.select(&:piece?)
    if piece_articles.any?
      covered = reserve_piece_packages(piece_articles, quantity, required_articles)
      quantity -= covered
    end

    if quantity.positive? && (article = select_filling_article(articles))
      required_articles[article.id] += 1
      reserved = article.reserve(1)
      raise if reserved != 1

      quantity -= reserved * article.quantity
    end

    add_missing_ingredient(entry, quantity) if quantity.positive?
  end

  def select_filling_article(articles)
    articles.select(&:available?).min_by { [it.quantity, it.priority] }
  end

  def update_plan
    GroupBoxArticle.where.not(box: Box.packed).delete_all # keep old plan for packed boxes
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

  def finish_articles
    @all_articles.each_value { it.each(&:finish) }
  end
end
