INGREDIENT_REGEXP = /^(?<quantity>\d+(?:,\d+)?) (?<unit>\S+) (?<name>[^()]*)(?:\((?<diets>.*)\))?$/

class Recipe < ApplicationRecord
  has_many :recipe_ingredients, dependent: :delete_all, autosave: true
  has_many :ingredients, through: :recipe_ingredients
  has_many :meals, -> { order(datetime: :asc) }, dependent: :destroy
  validates :name, presence: true
  validates :lama_uuid, uniqueness: true, if: :lama_uuid
  validates_associated :recipe_ingredients
  validate :ingredients_parseable

  scope :with_meal, -> { joins(:meals) }

  before_validation :set_ingredients_from_content

  def to_s
    name
  end

  private

  def set_ingredients_from_content
    @invalid_ingredients = []
    return unless content

    matches = ingredient_texts(content).map { |text| [text, text.match(INGREDIENT_REGEXP)] }
    @invalid_ingredients = matches.reject { |_text, match| match }.map(&:first)
    # Leave the ingredients untouched (and create no Ingredient or Diet records)
    # until every bold span parses; the validation below reports the rest.
    return if @invalid_ingredients.any?

    recipe_ingredients = build_recipe_ingredients(matches.map(&:last))
    if new_record?
      self.recipe_ingredients = recipe_ingredients
    else
      update_ingredients(recipe_ingredients)
    end
  end

  def update_ingredients(new_recipe_ingredients)
    existing_ids = recipe_ingredient_ids.dup
    new_recipe_ingredients.each do |recipe_ingredient|
      if (existing_ri = recipe_ingredients.detect { it.index == recipe_ingredient.index })
        existing_ids.delete(existing_ri.id)
        existing_ri.assign_attributes(
          recipe_ingredient.attributes.except('id', 'recipe_id', 'created_at', 'updated_at', 'positive_diets',
                                              'negative_diets')
        )
        existing_ri.positive_diets = recipe_ingredient.positive_diets
        existing_ri.negative_diets = recipe_ingredient.negative_diets
      else
        recipe_ingredients << recipe_ingredient
      end
    end
    recipe_ingredients.each do |existing_ri|
      existing_ri.mark_for_destruction if existing_ids.include?(existing_ri.id)
    end
  end

  def ingredients_parseable
    @invalid_ingredients&.each do |text|
      errors.add(:content, "enthält die ungültige Zutat „#{text}“ (Format: „500 g Mehl“ oder " \
                           '„5 g Mandeln (+vegan,-nussfrei)“)')
    end
  end

  def ingredient_texts(content)
    Nokogiri::HTML
      .parse(Kramdown::Document.new(content).to_html)
      .xpath('//strong|//b')
      .map(&:text)
  end

  def build_recipe_ingredients(matches)
    matches.each_with_index.map do |match, i|
      positive_diets, negative_diets = parse_diets(match[:diets])
      RecipeIngredient.new(
        ingredient: Ingredient.find_or_create_by(name: match[:name]),
        quantity: BigDecimal(match[:quantity].tr(',', '.')),
        unit: match[:unit],
        positive_diets: positive_diets,
        negative_diets: negative_diets,
        index: i
      )
    end
  end

  def parse_diets(diets)
    return [[], []] unless diets

    result = diets.split(',').group_by { |diet| diet[0] }
    [
      result.fetch('+', []).map { |diet| Diet.find_or_create_by(name: diet[1..]) },
      result.fetch('-', []).map { |diet| Diet.find_or_create_by(name: diet[1..]) }
    ]
  end
end
