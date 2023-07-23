select
  group_meal_participants.group_id,
  group_meal_participants.meal_id,
  group_meal_participants.participant_id,
  recipe_ingredients.id as recipe_ingredient_id,
  unit,
  intermediate_calculations.*,
  final_calculations.*
from group_meal_participants
join meals on meals.id = meal_id
join recipes on recipes.id = recipe_id
join recipe_ingredients using (recipe_id)
cross join lateral (
select
  quantity / servings as normalized_quantity,
  exists (
    select from positive_diet_ingredients where recipe_ingredient_id = recipe_ingredients.id
  ) as positive_diets_exist,
  exists (
    select from positive_diet_ingredients join diet_participants using(diet_id)
    where diet_participants.participant_id = group_meal_participants.participant_id
    and recipe_ingredient_id = recipe_ingredients.id
  ) as positive_diets_match,
  exists (
    select from negative_diet_ingredients join diet_participants using(diet_id)
    where diet_participants.participant_id = group_meal_participants.participant_id
    and recipe_ingredient_id = recipe_ingredients.id
  ) as negative_diets_match,
  exists (
    select from diets_ingredients join diet_participants using(diet_id)
    where diet_participants.participant_id = group_meal_participants.participant_id
    and diets_ingredients.ingredient_id = recipe_ingredients.ingredient_id
  ) as diets_match,
  (
    select
      alternative_id
    from ingredient_alternatives
    cross join lateral (
    select
      exists (
        select from diets_ingredients join diet_participants using(diet_id)
        where diet_participants.participant_id = group_meal_participants.participant_id
        and diets_ingredients.ingredient_id = alternative_id
      ) as alternative_diets_match
    ) as alternative_table
    where ingredient_id = recipe_ingredients.ingredient_id and not alternative_diets_match
    order by priority
    limit 1
  ) as alternative_ingredient_id
) as intermediate_calculations
cross join lateral (
select
  not negative_diets_match and (not positive_diets_exist or positive_diets_match) as include_ingredient_for_participant,
  (case diets_match
    when true then alternative_ingredient_id
    when false then ingredient_id
  end) as final_ingredient_id
) as final_calculations;
