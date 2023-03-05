/* manual individual meal participations */
SELECT
  group_id,
  meal_id,
  participant_id
FROM
  group_meal_participations
UNION
/* chosen or mandatory meal of group */
SELECT
  group_id,
  meal_id,
  participants.id as participant_id
FROM
  group_meals JOIN participants USING(group_id)
WHERE
  origin in (1,2);