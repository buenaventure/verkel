# frozen_string_literal: true

# Helpers for feeding demand into the ArticlePackingPlanner from specs.
#
# The planner reads what every group needs per box from the
# `group_box_ingredient_unit_caches` *materialized view*. In production that
# view is refreshed (GroupBoxIngredientUnitCache.do_calculate) from a long chain
# of upstream views (meals -> recipes -> participants -> hunger factors ->
# ingredient weights -> box assignment). Reconstructing that whole chain inside
# a unit spec just to obtain a handful of demand rows would be slow and
# extremely brittle, and a materialized view is read-only so we cannot simply
# `insert` into it either.
#
# Instead we temporarily swap the materialized view for a plain table with the
# same columns and insert demand rows directly. Each example runs inside a
# transaction (config.use_transactional_fixtures) and PostgreSQL has
# transactional DDL, so the DROP/CREATE is rolled back automatically at the end
# of every example and the real materialized view is restored untouched.
module DemandCacheHelpers
  delegate :connection, to: :'ActiveRecord::Base'

  # Replace the read-only materialized view with a writable table so specs can
  # inject demand rows. Mirrors the column list of the matview in structure.sql.
  def fake_demand_cache!
    connection.execute('DROP MATERIALIZED VIEW group_box_ingredient_unit_caches')
    connection.execute(<<~SQL.squish)
      CREATE TABLE group_box_ingredient_unit_caches (
        group_id bigint NOT NULL,
        box_id bigint NOT NULL,
        ingredient_id bigint NOT NULL,
        unit character varying,
        quantity numeric
      )
    SQL
  end

  # Records that `group` needs `quantity` of `ingredient` (in `unit`) in `box`.
  # This is exactly one row of the demand the planner consumes.
  def add_demand(group:, box:, ingredient:, quantity:, unit: 'g')
    sql = ActiveRecord::Base.send(
      :sanitize_sql_array,
      ['INSERT INTO group_box_ingredient_unit_caches ' \
       '(group_id, box_id, ingredient_id, unit, quantity) VALUES (?, ?, ?, ?, ?)',
       group.id, box.id, ingredient.id, unit, quantity]
    )
    connection.execute(sql)
  end
end

RSpec.configure do |config|
  config.include DemandCacheHelpers, :demand_cache
  config.before(:each, :demand_cache) { fake_demand_cache! }
end
