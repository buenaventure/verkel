class ArticlePackingPlanner
  include Calculatable

  DEPENDENCIES = [Article, Hoard, Order, OrderArticle, PackingLane, PackingLaneArticleStock, Supplier].freeze

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
      articles.map { |a| ArticleAvailabilityPlanner.new(a) }
    end
    @demands = GroupBoxIngredientUnitCache \
               .includes(:ingredient, :box) \
               .where.not(box: nil) \
               .all \
               .group_by(&:ingredient_unit)
  end

  def process_ingredient_unit(ingredient_unit, ingredient_entries)
    articles = @all_articles.fetch(ingredient_unit, [])
    ingredient_entries.sort_by { |e| e.box.datetime }.group_by(&:box).each do |box, entries|
      process_ingredient_unit_in_box(box, entries, articles)
    end
  end

  def process_ingredient_unit_in_box(box, entries, articles)
    return if box.packed?  # skip boxes which are done

    articles.each { |a| a.start_processing box }
    entries.each do |entry|
      process_ingredient_unit_in_group_box(entry, articles)
    end
    add_order_requirements(box, articles)
  end

  def process_ingredient_unit_in_group_box(entry, articles)
    required = entry.quantity
    required_articles = Hash.new(0)
    articles.each do |article|
      quantity_fit, = required.divmod(article.quantity)
      quantity_reserved = article.reserve(quantity_fit)
      required -= quantity_reserved * article.quantity
      required_articles[article.id] += quantity_reserved
    end
    handle_remaining(required, articles, required_articles, entry)
    add_required_articles(entry, required_articles)
  end

  def handle_remaining(quantity, articles, required_articles, entry)
    return unless quantity.positive?

    if (article = select_filling_article(articles))
      required_articles[article.id] += 1
      raise if article.reserve(1) != 1
    else
      add_missing_ingredient(entry, quantity)
    end
  end

  def select_filling_article(articles)
    articles.select(&:available?).min_by { |a| [a.quantity, a.priority] }
  end

  def update_plan
    GroupBoxArticle.where.not(box: Box.packed).delete_all # keep old plan for packed boxes
    @group_box_articles.any? && GroupBoxArticle.insert_all(
      @group_box_articles, unique_by: %i[group_id box_id article_id])
    ArticleBoxOrderRequirement.delete_all
    @article_box_order_requirements.any? && ArticleBoxOrderRequirement.insert_all(
      @article_box_order_requirements, unique_by: %i[article_id box_id])
    MissingIngredient.delete_all
    @missing_ingredients.any? && MissingIngredient.insert_all(
      @missing_ingredients, unique_by: %i[group_id box_id ingredient_id unit])
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

  def add_required_articles(entry, articles)
    @group_box_articles += articles.reject { |_, quantity| quantity.zero? }.map do |article_id, quantity|
      {
        group_id: entry.group_id,
        box_id: entry.box_id,
        article_id: article_id,
        quantity: quantity
      }
    end
  end

  def finish_articles
    @all_articles.each_value { |articles| articles.each(&:finish) }
  end
end
