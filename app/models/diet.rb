class Diet < ApplicationRecord
  has_and_belongs_to_many :ingredients
  has_many :diet_participants
  has_many :participants, through: :diet_participants

  has_many :positive_diet_ingredients, dependent: :restrict_with_error
  has_many :negative_diet_ingredients, dependent: :restrict_with_error

  validates :name, presence: true, uniqueness: true

  def to_s
    name
  end

  def positive_recipes
    Recipe.where(id:
      RecipeIngredient.where(id:
        positive_diet_ingredients.select(:recipe_ingredient_id)).select(:recipe_id))
  end

  def negative_recipes
    Recipe.where(id:
      RecipeIngredient.where(id:
        negative_diet_ingredients.select(:recipe_ingredient_id)).select(:recipe_id))
  end
end
