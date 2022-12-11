class MealIngredientBox < ApplicationRecord
  belongs_to :meal
  belongs_to :ingredient
  belongs_to :box

  scope :without_box, -> { where(box: nil) }
end
