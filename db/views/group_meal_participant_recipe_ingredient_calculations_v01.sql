select
  group_meal_participant_recipe_ingredient_subst_calculations.group_id,
  meal_id,
  participant_id,
  recipe_ingredient_id,
  unit,
  hunger_quantity,
  final_ingredient_id as ingredient_id
from group_meal_participant_recipe_ingredient_subst_calculations
join participants on participants.id = participant_id
join groups on groups.id = group_meal_participant_recipe_ingredient_subst_calculations.group_id
join ingredients on ingredients.id = final_ingredient_id
left join hunger_factors using(age)
cross join lateral (
select
  (case ingredients.uses_hunger_factor
    when true then normalized_quantity * coalesce(hunger_factors.factor, 1) * groups.hunger_factor
    when false then normalized_quantity
  end) as hunger_quantity
) as hunger_calculation
where include_ingredient_for_participant;
