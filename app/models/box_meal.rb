class BoxMeal < ApplicationRecord
  belongs_to :box
  belongs_to :meal
  belongs_to :recipe
end
