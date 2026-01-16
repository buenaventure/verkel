class GroupBox < ApplicationRecord
  belongs_to :group
  belongs_to :box
  delegate :datetime, to: :box

  def unit_sums_by_ingredient
    @unit_sums_by_ingredient ||=
      GroupBoxIngredientUnitCache
      .where(group:, box:)
      .group(:ingredient_id, :unit).sum(:quantity)
      .group_by { |k, _v| k[0] }
      .transform_values { |a| a.map { |b| QuantityUnit.new(b[1], b[0][1]) } }
  end

  def ingredients
    Ingredient.where(id: unit_sums_by_ingredient.keys).order(:commodity_group, :name)
  end

  def extra_ingredients
    ExtraIngredient.where(group:, box:)
  end

  def to_s
    "Kiste am #{I18n.l datetime} für #{group}"
  end

  def group_box_articles
    GroupBoxArticle
      .where(group:, box:)
      .non_zero
      .joins(article: :ingredient)
      .includes(article: %i[supplier ingredient])
      .order('ingredients.name', 'articles.quantity': :desc)
  end

  def route_array
    [box, group]
  end

  def breadcrumb_parent
    box
  end
end
