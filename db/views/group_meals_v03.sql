WITH group_meal_origin AS (
  /* manual individual meal participations */
  SELECT DISTINCT
    group_id,
    meal_id,
    0 as origin
  FROM
    group_meal_participations
  UNION ALL
  /* selected meals */
  SELECT
    group_id,
    meal_id,
    1 as origin
  FROM meal_selections
  UNION ALL
  /* mandatory meals */
  SELECT
    groups.id as group_id,
    meals.id as meal_id,
    2 as origin
  FROM meals CROSS JOIN groups
  WHERE
    meals.optional = false
)
SELECT
  group_id,
  meal_id,
  max(origin) as origin
FROM
  group_meal_origin
GROUP BY group_id, meal_id
;
