with meal_ingredients (meal_id, ingredient_id) as (
  select distinct meal_id, ingredient_id
  from group_meal_participant_recipe_ingredient_calculations
)
select
  meal_ingredients.*,
  (
    select boxes.id from boxes
    where boxes.datetime <= meals.datetime
      and (
        -- every ingredient of a bundled meal goes into the first box
        meals.bundle
      or
        -- a base box may contain every kind of ingredient
        boxes.box_type = 1
      or
        -- a default box may contain every ingredient but those belonging to the base box
        (boxes.box_type = 0 and ingredients.box_type != 1)
      or
        -- a fresh box may only contain fresh ingredients
        (boxes.box_type = 2 and ingredients.box_type = 2)
      )
    order by boxes.datetime desc
    limit 1
  ) as box_id
from meal_ingredients
join ingredients on ingredients.id = ingredient_id
join meals on meals.id = meal_id;
