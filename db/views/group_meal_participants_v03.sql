WITH mandatory_or_chosen_group_meals as (
  SELECT
    group_id,
    meal_id,
	datetime
  FROM
    group_meals
  JOIN meals on meal_id = meals.id
  WHERE
    origin in (1,2)
)
/* manual individual meal participations */
SELECT
  group_id,
  meal_id,
  participant_id
FROM
  group_meal_participations
UNION
/* chosen or mandatory meal of participants default group and no group change at that time */
SELECT
  group_id,
  meal_id,
  participants.id as participant_id
FROM
  mandatory_or_chosen_group_meals
  JOIN participants USING(group_id)
WHERE
  NOT EXISTS (
    SELECT FROM group_changes
    WHERE group_changes.participant_id = participants.id
      AND group_changes.timeframe @> datetime
  )
UNION
/* chosen or mandatory meal of the group changed to in the change timeframe */
SELECT
  mandatory_or_chosen_group_meals.group_id,
  meal_id,
  group_changes.participant_id AS participant_id
FROM
  mandatory_or_chosen_group_meals
  JOIN group_changes ON group_changes.timeframe @> datetime
    AND group_changes.group_id = mandatory_or_chosen_group_meals.group_id
;