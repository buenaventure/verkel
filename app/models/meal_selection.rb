class MealSelection < ApplicationRecord
  belongs_to :group
  belongs_to :meal

  validates :meal, uniqueness: { scope: :group, message: 'ist bereits gewählt' }

  delegate :datetime, to: :meal
end
