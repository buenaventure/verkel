class Meal < ApplicationRecord
  default_scope { order(datetime: :asc) }

  belongs_to :recipe
  has_many :group_meals
  has_one :box_meal
  has_one :box, through: :box_meal
  has_many :group_meal_participations, dependent: :destroy
  has_many :group_meal_participants
  has_many :meal_selections

  scope :optional, -> { where(optional: true) }
  scope :unselected_by, ->(group) { where.not(id: group.meal_selections.pluck(:meal_id)) }

  after_save :delete_non_optional_meal_selections

  def serving_estimation
    @serving_estimation ||= Rails.application.config.estimated_participants * estimated_share
  end

  def estimated_ingredients
    return nil unless recipe&.servings

    recipe.recipe_ingredients.includes(:ingredient).order('ingredients.name').map do |recipe_ingredient|
      needed_servings = self.needed_servings(recipe_ingredient.positive_diet_ids)
      factor = needed_servings / recipe.servings
      {
        needed_servings:,
        factor:,
        quantity_unit: QuantityUnit.new(recipe_ingredient.quantity * factor, recipe_ingredient.unit),
        ingredient: recipe_ingredient.ingredient
      }
    end
  end

  def needed_servings(positive_diet_ids)
    if positive_diet_ids.empty?
      serving_estimation
    else
      0
    end
  end

  def to_s
    "#{I18n.l datetime} #{name} \"#{recipe.name}\""
  end

  def servings
    group_meal_participants.count
  end

  def delete_non_optional_meal_selections
    return if optional?

    meal_selections.delete_all
  end
end
