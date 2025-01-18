INGREDIENT_REGEXP = /^(?<quantity>\d+(?:,\d+)?) (?<unit>\S+) (?<name>[^()]*)(?:\((?<diets>.*)\))?$/

class Recipe < ApplicationRecord
  has_many :recipe_ingredients, dependent: :delete_all
  has_many :ingredients, through: :recipe_ingredients
  has_many :meals, -> { order(datetime: :asc) }, dependent: :destroy
  validates :name, presence: true
  validates :lama_uuid, uniqueness: true, if: :lama_uuid

  scope :with_meal, -> { joins(:meals) }

  before_save :set_ingredients_from_content

  def to_s
    name
  end

  private

  def set_ingredients_from_content
    return unless content

    recipe_ingredients = parse_ingredients(content)
    if new_record?
      self.recipe_ingredients = recipe_ingredients
    else
      update_ingredients(recipe_ingredients)
    end
  end

  def update_ingredients(new_recipe_ingredients)
    existing_ids = recipe_ingredient_ids
    new_recipe_ingredients.each do |recipe_ingredient|
      if (existing_ri = recipe_ingredients.find_by(index: recipe_ingredient.index))
        existing_ids.delete(existing_ri.id)
        existing_ri.update!(
          recipe_ingredient.attributes.except('id', 'recipe_id', 'created_at', 'updated_at', 'positive_diets',
                                              'negative_diets')
        )
        existing_ri.positive_diets = recipe_ingredient.positive_diets
        existing_ri.negative_diets = recipe_ingredient.negative_diets
      else
        recipe_ingredients << recipe_ingredient
      end
    end
    recipe_ingredients.where(id: existing_ids).destroy_all
  end

  def parse_ingredients(content)
    Nokogiri::HTML
      .parse(Kramdown::Document.new(content).to_html) \
      .xpath('//strong|//b')\
      .each_with_index.map do |b, i|
        match = b.text.match(INGREDIENT_REGEXP)
        raise "ungültige Zutat \"#{b.text}\"" unless match

        positive_diets, negative_diets = parse_diets(match[:diets])
        RecipeIngredient.new(
          ingredient: Ingredient.find_or_create_by(name: match[:name]),
          quantity: BigDecimal(match[:quantity].gsub(',', '.')),
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
