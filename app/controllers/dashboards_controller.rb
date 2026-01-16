class DashboardsController < ApplicationController
  authorize_resource :dashboard, class: false
  before_action :set_breadcrumbs

  def show; end

  def groups_missing_packing_lane
    @groups_missing_packing_lane = Group.where(packing_lane: nil)
  end

  def ingredients_missing_article
    @ingredients_missing_article =
      Ingredient
      .where(id: GroupBoxIngredientUnitCache.all.select(:ingredient_id))
      .joins('left outer join articles on ingredients.id = articles.ingredient_id')
      .where('articles.id is NULL')
  end

  def ingredients_without_box
    @ingredients_without_box =
      MealIngredientBox
      .includes(:ingredient, meal: :recipe)
      .joins(:meal).order('meals.datetime')
      .without_box
  end

  def recipes_without_content
    @recipes_without_content =
      Recipe
      .joins(:meals)
      .where(content: '')
      .uniq
  end

  def missing_ingredients
    missing_ingredients =
      MissingIngredient
      .group(:box_id, :ingredient_id, :unit).sum(:quantity)
    @missing_sums =
      missing_ingredients
      .group_by { |k, _v| k[0] }
      .transform_values do |a|
        a.group_by { |k, _v| k[1] }.transform_values do |b|
          b.map { |c| QuantityUnit.new(c[1], c[0][2]) }
        end
      end
    @ingredients = Ingredient.where(id: missing_ingredients.keys.map { |k| k[1] }).index_by { |i| i.id }
    @boxes = Box.where(id: missing_ingredients.keys.map { |k| k[0] })
  end

  def upcoming_boxes
    @boxes = Box.where.not(status: :packed).limit(6)
  end

  def upcoming_order_requirements
    @suppliers = Supplier.with_next_order_data.order('next_required_order_date').select do |supplier|
      !supplier.next_order_needed_date.nil? &&
        supplier.next_required_order_date <= DateTime.current + 48.hours
    end
  end

  def upcoming_orders
    @orders = Order.where(state: %i[planned ordered delivered]).includes(:supplier).select do |order|
      case order.state
      when 'planned' then order.latest_order_date <= DateTime.current + 48.hours
      when 'ordered' then order.coverage_begin <= DateTime.current + 48.hours
      when 'delivered' then true
      end
    end
  end

  private

  def set_breadcrumbs
    @breadcrumbs = []
  end
end
