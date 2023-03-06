class Ingredient < ApplicationRecord
  enum box_type: { default: 0, base_box: 1, fresh_box: 2 }

  has_many :recipe_ingredients, dependent: :destroy
  has_many :recipes, through: :recipe_ingredients
  has_many :ingredient_weights, dependent: :delete_all
  has_many :articles, dependent: :destroy
  has_many :suppliers, -> { distinc }, through: :articles
  has_many :extra_ingredients
  has_many :ingredient_alternatives, dependent: :destroy
  has_and_belongs_to_many :diets
  has_many :group_box_ingredient_unit_caches
  has_many :boxes, -> { distinct }, through: :group_box_ingredient_unit_caches
  has_many :missing_ingredients

  scope :in_meal_or_extra, lambda {
    left_outer_joins(:extra_ingredients, recipes: :meals) \
      .where('("extra_ingredients"."id" IS NOT NULL OR "meals"."id" IS NOT NULL)').distinct
  }

  validates :name, presence: true
  validates :box_type, presence: true
  validates :uses_hunger_factor, inclusion: { in: [true, false] }

  def in_meals
    Meal \
      .joins(recipe: :recipe_ingredients) \
      .where(recipe: { recipe_ingredients: { ingredient_id: id } }) \
      .joins('LEFT OUTER JOIN ingredient_weights ON ' \
        'ingredient_weights.ingredient_id = recipe_ingredients.ingredient_id AND ' \
        'ingredient_weights.unit = recipe_ingredients.unit') \
      .select(
        'meals.*',
        'recipe.name', 'recipe.servings AS recipe_servings',
        'recipe_ingredients.quantity', 'recipe_ingredients.unit',
        '(select array_agg(diet_id) from positive_diet_ingredients where recipe_ingredient_id = recipe_ingredients.id) as positive_diet_ids',
        'ingredient_weights.weight'
      ).order(datetime: :asc)
  end

  def to_s
    name
  end

  def unit_sums
    @unit_sums ||= QuantityUnits.new(
      group_box_ingredient_unit_caches \
      .group(:unit).sum(:quantity)\
      .map { |a| QuantityUnit.new(a[1], a[0]) }
    )
  end

  def unit_sums_by_box
    @unit_sums_by_box = \
      group_box_ingredient_unit_caches \
      .group(:box_id, :unit).sum(:quantity)\
      .group_by { |k, _v| k[0] } \
      .transform_values { |a| QuantityUnits.new(a.map { |b| QuantityUnit.new(b[1], b[0][1]) }) }
  end

  def missing_ingredient_sums
    @missing_ingredient_sums ||= QuantityUnits.new(
      missing_ingredients \
      .group(:unit).sum(:quantity)\
      .map { |a| QuantityUnit.new(a[1], a[0]) }
    )
  end

  def missing_ingredient_sums_by_box
    @missing_ingredient_sums_by_box = \
      missing_ingredients \
      .group(:box_id, :unit).sum(:quantity)\
      .group_by { |k, _v| k[0] } \
      .transform_values { |a| QuantityUnits.new(a.map { |b| QuantityUnit.new(b[1], b[0][1]) }) }
  end

  def order_requirements
    @order_requirements = \
      ArticleBoxOrderRequirement \
      .joins(:article).includes(:article) \
      .merge(Article.unscope(:order).where(ingredient_id: id)) \
      .group_by(&:box_id).map do |box_id, order_requirements|
        [box_id, OrderRequirement.new(
          box_id:,
          quantity: QuantityUnit.sum(order_requirements.map(&:quantity_unit)),
          stock: QuantityUnit.sum(order_requirements.map(&:stock_quantity_unit)),
          ordered: QuantityUnit.sum(order_requirements.map(&:ordered_quantity_unit))
        )]
      end.to_h
  end

  def order_requirement_of(box)
    order_requirements.fetch(box.id, NoOrderRequirement.new(value: QuantityUnits.new))
  end
end
