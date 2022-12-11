class Participant < ApplicationRecord
  belongs_to :group, optional: true
  has_many :diet_participants, dependent: :destroy
  has_many :diets, through: :diet_participants
  has_many :group_meal_participations, dependent: :destroy
  has_many :group_meal_participants, -> { joins(:meal).order('meals.datetime': :asc) }

  validates :age, presence: true, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }

  def to_s
    "##{id}"
  end
end
