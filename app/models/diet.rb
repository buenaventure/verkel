class Diet < ApplicationRecord
  has_and_belongs_to_many :ingredients
  has_many :diet_participants
  has_many :participants, through: :diet_participants

  validates :name, presence: true, uniqueness: true

  def to_s
    name
  end
end
