SELECT
  group_box_articles.id AS group_box_article_id,
  group_box_articles.group_id,
  group_box_articles.box_id,
  group_box_articles.article_id,
  group_box_articles.quantity,
  articles.price AS unit_price,
  ROUND((group_box_articles.quantity * articles.price)::numeric, 2) AS line_total,
  (boxes.status = 2) AS is_final
FROM group_box_articles
JOIN articles ON articles.id = group_box_articles.article_id
JOIN boxes ON boxes.id = group_box_articles.box_id
WHERE group_box_articles.quantity <> 0;
