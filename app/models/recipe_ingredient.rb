class RecipeIngredient < ApplicationRecord
  include NormalizedQuantityUnit

  belongs_to :recipe
  belongs_to :ingredient
  has_many :positive_diet_ingredients
  has_many :negative_diet_ingredients
  has_many :positive_diets, through: :positive_diet_ingredients, class_name: 'Diet', source: :diet
  has_many :negative_diets, through: :negative_diet_ingredients, class_name: 'Diet', source: :diet

  default_scope { order(recipe_id: :asc, index: :asc) }

  def to_s
    "#{quantity} #{unit} #{ingredient.name}"
  end

  def diets?
    positive_diet_ingredients.any? || negative_diet_ingredients.any?
  end

  def diets_s
    (
      positive_diets.map do |diet|
        "+#{diet.name}"
      end + \
      negative_diets.map do |diet|
        "-#{diet.name}"
      end
    ).join(', ')
  end
end
