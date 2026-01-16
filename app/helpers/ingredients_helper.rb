module IngredientsHelper
  def estimated_need_per_meal(ingredient)
    ingredient
      .in_meals.map do |meal_ingredient|
      if meal_ingredient.recipe_servings
        factor = meal_ingredient.needed_servings(
          meal_ingredient.positive_diet_ids || []
        ) / meal_ingredient.recipe_servings
        {
          quantity_unit: QuantityUnit.new(
            meal_ingredient.quantity * factor,
            meal_ingredient.unit
          ),
          meal: meal_ingredient,
          weight: meal_ingredient.weight
        }
      else
        {
          meal: meal_ingredient,
          quantity_unit: QuantityUnit.new(1, 'Faktor unklar')
        }
      end
    end.group_by do |need|
      [need[:meal].id, need[:quantity_unit].unit]
    end
    .map do |meal_unit, needs|
      raise unless needs.all? { |need| need[:weight] == needs[0][:weight] }

      {
        meal: needs[0][:meal],
        weight: needs[0][:weight],
        quantity_unit: QuantityUnit.new(
          needs.map { |need| need[:quantity_unit].quantity }.sum,
          meal_unit[1]
        )
      }
    end
  end

  def estimated_need_total(ingredient)
    QuantityUnit.sum(
      estimated_need_per_meal(ingredient)
        .map { |need| estimate_weight(need) }
    )
  end

  def estimate_weight(need)
    return need[:quantity_unit] if need[:quantity_unit].unit == 'g' || !need[:weight]

    QuantityUnit.new(need[:quantity_unit].quantity * need[:weight], 'g')
  end

  def missing_alternatives_stats(ingredient_problems)
    ingredient_problems.group_by(&:diet_string).map do |diet, diet_problems|
      participants = diet_problems.map(&:participant).uniq
      groups = diet_problems.map(&:group).uniq
      meals = diet_problems.map(&:meal).uniq
      [
        diet, {
          participants: participants,
          groups: groups,
          meals: meals
        }
      ]
    end.to_h
  end

  def problems_count_color(count)
    case count
    when ..1 then 'success'
    when ..5 then 'warning'
    else 'danger'
    end
  end
end
