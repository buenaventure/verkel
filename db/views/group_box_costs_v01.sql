SELECT
  group_box_article_costs.group_id,
  group_box_article_costs.box_id,
  boxes.datetime AS box_datetime,
  group_box_article_costs.is_final,
  SUM(group_box_article_costs.line_total) AS total_cost
FROM group_box_article_costs
JOIN boxes ON boxes.id = group_box_article_costs.box_id
GROUP BY
  group_box_article_costs.group_id,
  group_box_article_costs.box_id,
  boxes.datetime,
  group_box_article_costs.is_final;
