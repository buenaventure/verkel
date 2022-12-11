class NegativeDietIngredient < ApplicationRecord
  belongs_to :diet
  belongs_to :recipe_ingredient
end
