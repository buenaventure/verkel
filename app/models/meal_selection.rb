class MealSelection < ApplicationRecord
  self.primary_key = %i[group_id meal_id]
  belongs_to :group
  belongs_to :meal

  validates :meal, uniqueness: { scope: :group, message: 'ist bereits gewählt' }

  delegate :datetime, to: :meal
end
