class IngredientAlternative < ApplicationRecord
  belongs_to :ingredient
  belongs_to :alternative, class_name: 'Ingredient'

  validates :priority, uniqueness: { scope: :ingredient }

  def to_s
    "Alternative: #{alternative}"
  end

  def self.breadcrumb_index_on_parent
    true
  end

  private

  def breadcrumb_parent
    ingredient
  end
end
