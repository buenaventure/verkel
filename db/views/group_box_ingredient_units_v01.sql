with ingredient_sums as (
    select
      group_id,
      box_id,
      ingredient_id,
      group_meal_participant_recipe_ingredient_calculations.unit,
      sum(hunger_quantity) as quantity
    from group_meal_participant_recipe_ingredient_calculations
    join meal_ingredient_boxes using(meal_id, ingredient_id)
    group by group_id, box_id, ingredient_id, group_meal_participant_recipe_ingredient_calculations.unit
  )
  , weighted_ingredient_sums as (
    select
      group_id,
      box_id,
      ingredient_id,
      pack_unit,
      pack_quantity
    from ingredient_sums
    left join ingredient_weights using(ingredient_id, unit)
    cross join lateral (
    select
      case
        when ingredient_weights.weight is not null then ingredient_weights.weight * quantity
        when unit = 'g' then quantity
      end as resulting_weight
    ) as weight_calculation
    cross join lateral (
    select
      coalesce(resulting_weight, quantity) as pack_quantity,
      (select case
        when resulting_weight is not null then 'g'
        else unit
      end) as pack_unit
    ) as packing
  )
  , weighted_ingredient_sums_with_extra_ingredients as (
    select
      group_id,
      box_id,
      ingredient_id,
      pack_unit as unit,
      pack_quantity as quantity
    from weighted_ingredient_sums
    union all
    select
      group_id,
      box_id,
      ingredient_id,
      unit,
      quantity
    from extra_ingredients
  )
select
  group_id,
  box_id,
  ingredient_id,
  unit,
  sum(quantity)::numeric(8,2) as quantity
from weighted_ingredient_sums_with_extra_ingredients
group by group_id, box_id, ingredient_id, unit;
