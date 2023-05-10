# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.0].define(version: 2023_05_10_193610) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "action_text_rich_texts", force: :cascade do |t|
    t.string "name", null: false
    t.text "body"
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["record_type", "record_id", "name"], name: "index_action_text_rich_texts_uniqueness", unique: true
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "article_box_order_requirements", force: :cascade do |t|
    t.bigint "article_id", null: false
    t.bigint "box_id", null: false
    t.decimal "quantity", precision: 8
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.decimal "stock", precision: 8
    t.decimal "ordered", precision: 8
    t.index ["article_id", "box_id"], name: "index_article_box_order_requirements_on_article_and_box", unique: true
    t.index ["article_id"], name: "index_article_box_order_requirements_on_article_id"
    t.index ["box_id"], name: "index_article_box_order_requirements_on_box_id"
  end

  create_table "articles", force: :cascade do |t|
    t.bigint "supplier_id", null: false
    t.decimal "price", precision: 8, scale: 5
    t.string "unit"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "ingredient_id", null: false
    t.text "notes"
    t.decimal "quantity", precision: 8, scale: 1
    t.decimal "stock", precision: 8, default: "0", null: false
    t.integer "priority", default: 0, null: false
    t.string "name", default: "", null: false
    t.decimal "order_limit", precision: 8
    t.integer "packing_type", default: 0, null: false
    t.boolean "needs_cooling", default: false, null: false
    t.integer "nr"
    t.index ["ingredient_id"], name: "index_articles_on_ingredient_id"
    t.index ["nr"], name: "index_articles_on_nr", unique: true
    t.index ["supplier_id"], name: "index_articles_on_supplier_id"
  end

  create_table "boxes", force: :cascade do |t|
    t.datetime "datetime"
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.integer "box_type", default: 0, null: false
    t.integer "status", default: 0, null: false
    t.index ["datetime"], name: "index_boxes_on_datetime", unique: true
  end

  create_table "diet_participants", force: :cascade do |t|
    t.bigint "diet_id"
    t.bigint "participant_id"
    t.index ["diet_id", "participant_id"], name: "index_diet_participants_on_diet_id_and_participant_id", unique: true
    t.index ["diet_id"], name: "index_diet_participants_on_diet_id"
    t.index ["participant_id"], name: "index_diet_participants_on_participant_id"
  end

  create_table "diets", force: :cascade do |t|
    t.string "name"
    t.string "category"
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.uuid "lama_uuid"
    t.index ["lama_uuid"], name: "index_diets_on_lama_uuid", unique: true
    t.index ["name"], name: "index_diets_on_name", unique: true
  end

  create_table "diets_ingredients", id: false, force: :cascade do |t|
    t.bigint "diet_id"
    t.bigint "ingredient_id"
    t.index ["diet_id", "ingredient_id"], name: "index_diets_ingredients_on_diet_id_and_ingredient_id", unique: true
    t.index ["diet_id"], name: "index_diets_ingredients_on_diet_id"
    t.index ["ingredient_id"], name: "index_diets_ingredients_on_ingredient_id"
  end

  create_table "extra_ingredients", force: :cascade do |t|
    t.bigint "group_id", null: false
    t.bigint "box_id", null: false
    t.bigint "ingredient_id", null: false
    t.decimal "quantity", precision: 7, scale: 2
    t.string "unit"
    t.string "purpose"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["box_id"], name: "index_extra_ingredients_on_box_id"
    t.index ["group_id"], name: "index_extra_ingredients_on_group_id"
    t.index ["ingredient_id"], name: "index_extra_ingredients_on_ingredient_id"
  end

  create_table "group_box_articles", force: :cascade do |t|
    t.bigint "group_id", null: false
    t.bigint "box_id", null: false
    t.bigint "article_id", null: false
    t.decimal "quantity", precision: 8
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["article_id"], name: "index_group_box_articles_on_article_id"
    t.index ["box_id"], name: "index_group_box_articles_on_box_id"
    t.index ["group_id", "box_id", "article_id"], name: "index_group_box_articles_on_group_box_and_article", unique: true
    t.index ["group_id"], name: "index_group_box_articles_on_group_id"
  end

  create_table "group_meal_participations", force: :cascade do |t|
    t.bigint "group_id", null: false
    t.bigint "meal_id", null: false
    t.bigint "participant_id", null: false
    t.boolean "lama_imported", default: false, null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["group_id", "meal_id", "participant_id"], name: "index_group_meal_participations_on_group_meal_participant", unique: true
    t.index ["group_id"], name: "index_group_meal_participations_on_group_id"
    t.index ["meal_id"], name: "index_group_meal_participations_on_meal_id"
    t.index ["participant_id"], name: "index_group_meal_participations_on_participant_id"
  end

  create_table "groups", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.uuid "lama_uuid"
    t.decimal "hunger_factor", precision: 4, scale: 3, default: "1.0", null: false
    t.bigint "packing_lane_id"
    t.string "internal_name"
    t.index ["internal_name"], name: "index_groups_on_internal_name", unique: true
    t.index ["lama_uuid"], name: "index_groups_on_lama_uuid", unique: true
    t.index ["name"], name: "index_groups_on_name", unique: true
    t.index ["packing_lane_id"], name: "index_groups_on_packing_lane_id"
  end

  create_table "hoards", force: :cascade do |t|
    t.bigint "article_id", null: false
    t.decimal "quantity", precision: 8, null: false
    t.datetime "until", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.decimal "missing_quantity", precision: 8, default: "0", null: false
    t.index ["article_id"], name: "index_hoards_on_article_id"
  end

  create_table "hunger_factors", force: :cascade do |t|
    t.integer "age", null: false
    t.decimal "factor", precision: 4, scale: 3, null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["age"], name: "index_hunger_factors_on_age", unique: true
  end

  create_table "ingredient_alternatives", force: :cascade do |t|
    t.bigint "ingredient_id", null: false
    t.bigint "alternative_id", null: false
    t.integer "priority", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["alternative_id"], name: "index_ingredient_alternatives_on_alternative_id"
    t.index ["ingredient_id", "alternative_id"], name: "index_ingredient_alternatives_on_ingredient_alternative", unique: true
    t.index ["ingredient_id", "priority"], name: "index_ingredient_alternatives_on_ingredient_id_and_priority", unique: true
    t.index ["ingredient_id"], name: "index_ingredient_alternatives_on_ingredient_id"
  end

  create_table "ingredient_weights", force: :cascade do |t|
    t.bigint "ingredient_id", null: false
    t.string "unit"
    t.decimal "weight", precision: 7, scale: 2
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["ingredient_id", "unit"], name: "index_ingredient_weights_on_ingredient_id_and_unit", unique: true
    t.index ["ingredient_id"], name: "index_ingredient_weights_on_ingredient_id"
  end

  create_table "ingredients", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "commodity_group"
    t.boolean "no_buy", default: false, null: false
    t.boolean "uses_hunger_factor", default: false, null: false
    t.integer "box_type", default: 0, null: false
    t.index ["name"], name: "index_ingredients_on_name", unique: true
  end

  create_table "meal_selections", primary_key: ["group_id", "meal_id"], force: :cascade do |t|
    t.bigint "group_id", null: false
    t.bigint "meal_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["group_id"], name: "index_meal_selections_on_group_id"
    t.index ["meal_id"], name: "index_meal_selections_on_meal_id"
  end

  create_table "meals", force: :cascade do |t|
    t.datetime "datetime"
    t.bigint "recipe_id", null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.decimal "estimated_share", precision: 3, scale: 2, default: "1.0"
    t.boolean "optional", default: false, null: false
    t.string "name"
    t.uuid "lama_slot_uuid"
    t.boolean "bundle", default: false, null: false
    t.index ["lama_slot_uuid", "recipe_id"], name: "index_meals_on_lama_slot_uuid_and_recipe_id", unique: true
    t.index ["recipe_id"], name: "index_meals_on_recipe_id"
  end

  create_table "missing_ingredients", force: :cascade do |t|
    t.bigint "group_id", null: false
    t.bigint "box_id", null: false
    t.bigint "ingredient_id", null: false
    t.decimal "quantity", precision: 8, scale: 2
    t.string "unit"
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["box_id"], name: "index_missing_ingredients_on_box_id"
    t.index ["group_id", "box_id", "ingredient_id", "unit"], name: "index_missing_ingredients_on_group_box_ingredient_and_unit", unique: true
    t.index ["group_id"], name: "index_missing_ingredients_on_group_id"
    t.index ["ingredient_id"], name: "index_missing_ingredients_on_ingredient_id"
  end

  create_table "negative_diet_ingredients", id: false, force: :cascade do |t|
    t.bigint "diet_id"
    t.bigint "recipe_ingredient_id"
    t.index ["diet_id", "recipe_ingredient_id"], name: "index_negative_diet_ingredients_diet_recipe_ingredient", unique: true
    t.index ["diet_id"], name: "index_negative_diet_ingredients_on_diet_id"
    t.index ["recipe_ingredient_id"], name: "index_negative_diet_ingredients_on_recipe_ingredient_id"
  end

  create_table "order_articles", force: :cascade do |t|
    t.bigint "order_id", null: false
    t.bigint "article_id", null: false
    t.decimal "quantity_ordered", precision: 8, default: "0"
    t.decimal "quantity_delivered", precision: 8, default: "0"
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["article_id"], name: "index_order_articles_on_article_id"
    t.index ["order_id", "article_id"], name: "index_order_articles_on_order_and_article", unique: true
    t.index ["order_id"], name: "index_order_articles_on_order_id"
  end

  create_table "orders", force: :cascade do |t|
    t.bigint "supplier_id", null: false
    t.tsrange "coverage"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "state", default: 0, null: false
    t.index ["supplier_id"], name: "index_orders_on_supplier_id"
  end

  create_table "packing_lane_article_stocks", force: :cascade do |t|
    t.bigint "packing_lane_id", null: false
    t.bigint "article_id", null: false
    t.decimal "quantity", precision: 8, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "box_id", null: false
    t.index ["article_id"], name: "index_packing_lane_article_stocks_on_article_id"
    t.index ["box_id"], name: "index_packing_lane_article_stocks_on_box_id"
    t.index ["packing_lane_id", "box_id", "article_id"], name: "packing_lane_article_stock_unique", unique: true
    t.index ["packing_lane_id"], name: "index_packing_lane_article_stocks_on_packing_lane_id"
  end

  create_table "packing_lanes", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_packing_lanes_on_name", unique: true
  end

  create_table "participants", force: :cascade do |t|
    t.bigint "group_id"
    t.integer "age"
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.uuid "lama_uuid"
    t.string "comment"
    t.string "external_id"
    t.index ["external_id"], name: "index_participants_on_external_id", unique: true
    t.index ["group_id"], name: "index_participants_on_group_id"
    t.index ["lama_uuid"], name: "index_participants_on_lama_uuid", unique: true
  end

  create_table "positive_diet_ingredients", id: false, force: :cascade do |t|
    t.bigint "diet_id"
    t.bigint "recipe_ingredient_id"
    t.index ["diet_id", "recipe_ingredient_id"], name: "index_positive_diet_ingredients_diet_recipe_ingredient", unique: true
    t.index ["diet_id"], name: "index_positive_diet_ingredients_on_diet_id"
    t.index ["recipe_ingredient_id"], name: "index_positive_diet_ingredients_on_recipe_ingredient_id"
  end

  create_table "recipe_ingredients", force: :cascade do |t|
    t.bigint "recipe_id", null: false
    t.bigint "ingredient_id", null: false
    t.decimal "quantity", precision: 7, scale: 2
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "unit"
    t.integer "index"
    t.index ["ingredient_id"], name: "index_recipe_ingredients_on_ingredient_id"
    t.index ["recipe_id", "index"], name: "index_recipe_ingredients_on_recipe_id_and_index", unique: true
    t.index ["recipe_id"], name: "index_recipe_ingredients_on_recipe_id"
  end

  create_table "recipes", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.text "content", default: "", null: false
    t.decimal "servings", precision: 6, scale: 2, default: "1.0"
    t.uuid "lama_uuid"
    t.string "diet_notes"
    t.index ["lama_uuid"], name: "index_recipes_on_lama_uuid", unique: true
    t.index ["name"], name: "index_recipes_on_name", unique: true
  end

  create_table "stock_changes", force: :cascade do |t|
    t.bigint "article_id", null: false
    t.bigint "user_id", null: false
    t.decimal "quantity", precision: 8, null: false
    t.decimal "result", precision: 8, null: false
    t.string "reference"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["article_id"], name: "index_stock_changes_on_article_id"
    t.index ["user_id"], name: "index_stock_changes_on_user_id"
  end

  create_table "suppliers", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "delivery_time", default: 72, null: false
    t.text "address"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.datetime "remember_created_at"
    t.integer "failed_attempts", default: 0, null: false
    t.datetime "locked_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.integer "role", default: 0, null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "article_box_order_requirements", "articles", on_delete: :cascade
  add_foreign_key "article_box_order_requirements", "boxes", on_delete: :cascade
  add_foreign_key "articles", "ingredients"
  add_foreign_key "articles", "suppliers"
  add_foreign_key "extra_ingredients", "boxes"
  add_foreign_key "extra_ingredients", "groups"
  add_foreign_key "extra_ingredients", "ingredients"
  add_foreign_key "group_box_articles", "articles", on_delete: :cascade
  add_foreign_key "group_box_articles", "boxes", on_delete: :cascade
  add_foreign_key "group_box_articles", "groups", on_delete: :cascade
  add_foreign_key "group_meal_participations", "groups", on_delete: :cascade
  add_foreign_key "group_meal_participations", "meals", on_delete: :cascade
  add_foreign_key "group_meal_participations", "participants", on_delete: :cascade
  add_foreign_key "groups", "packing_lanes"
  add_foreign_key "hoards", "articles"
  add_foreign_key "ingredient_alternatives", "ingredients"
  add_foreign_key "ingredient_alternatives", "ingredients", column: "alternative_id"
  add_foreign_key "ingredient_weights", "ingredients"
  add_foreign_key "meal_selections", "groups"
  add_foreign_key "meal_selections", "meals"
  add_foreign_key "meals", "recipes"
  add_foreign_key "missing_ingredients", "boxes", on_delete: :cascade
  add_foreign_key "missing_ingredients", "groups", on_delete: :cascade
  add_foreign_key "missing_ingredients", "ingredients", on_delete: :cascade
  add_foreign_key "order_articles", "articles"
  add_foreign_key "order_articles", "orders"
  add_foreign_key "orders", "suppliers"
  add_foreign_key "packing_lane_article_stocks", "articles"
  add_foreign_key "packing_lane_article_stocks", "boxes"
  add_foreign_key "packing_lane_article_stocks", "packing_lanes"
  add_foreign_key "participants", "groups"
  add_foreign_key "recipe_ingredients", "ingredients"
  add_foreign_key "recipe_ingredients", "recipes"
  add_foreign_key "stock_changes", "articles"
  add_foreign_key "stock_changes", "users"

  create_view "box_meals", sql_definition: <<-SQL
      SELECT meals.id AS meal_id,
      recipes.id AS recipe_id,
      ( SELECT boxes.id
             FROM boxes
            WHERE (boxes.datetime <= meals.datetime)
            ORDER BY boxes.datetime DESC
           LIMIT 1) AS box_id
     FROM (meals
       JOIN recipes ON ((recipes.id = meals.recipe_id)));
  SQL
  create_view "group_meal_participants", sql_definition: <<-SQL
      SELECT group_meal_participations.group_id,
      group_meal_participations.meal_id,
      group_meal_participations.participant_id
     FROM group_meal_participations
  UNION
   SELECT group_meals.group_id,
      group_meals.meal_id,
      participants.id AS participant_id
     FROM (group_meals
       JOIN participants USING (group_id))
    WHERE (group_meals.origin = ANY (ARRAY[1, 2]));
  SQL
  create_view "group_meal_participant_recipe_ingredient_subst_calculations", sql_definition: <<-SQL
      SELECT group_meal_participants.group_id,
      group_meal_participants.meal_id,
      group_meal_participants.participant_id,
      recipe_ingredients.id AS recipe_ingredient_id,
      recipe_ingredients.unit,
      intermediate_calculations.normalized_quantity,
      intermediate_calculations.positive_diets_exist,
      intermediate_calculations.positive_diets_match,
      intermediate_calculations.negative_diets_match,
      intermediate_calculations.diets_match,
      intermediate_calculations.alternative_ingredient_id,
      final_calculations.include_ingredient_for_participant,
      final_calculations.final_ingredient_id
     FROM (((((group_meal_participants
       JOIN meals ON ((meals.id = group_meal_participants.meal_id)))
       JOIN recipes ON ((recipes.id = meals.recipe_id)))
       JOIN recipe_ingredients USING (recipe_id))
       CROSS JOIN LATERAL ( SELECT (recipe_ingredients.quantity / recipes.servings) AS normalized_quantity,
              (EXISTS ( SELECT
                     FROM positive_diet_ingredients
                    WHERE (positive_diet_ingredients.recipe_ingredient_id = recipe_ingredients.id))) AS positive_diets_exist,
              (EXISTS ( SELECT
                     FROM (positive_diet_ingredients
                       JOIN diet_participants USING (diet_id))
                    WHERE ((diet_participants.participant_id = group_meal_participants.participant_id) AND (positive_diet_ingredients.recipe_ingredient_id = recipe_ingredients.id)))) AS positive_diets_match,
              (EXISTS ( SELECT
                     FROM (negative_diet_ingredients
                       JOIN diet_participants USING (diet_id))
                    WHERE ((diet_participants.participant_id = group_meal_participants.participant_id) AND (negative_diet_ingredients.recipe_ingredient_id = recipe_ingredients.id)))) AS negative_diets_match,
              (EXISTS ( SELECT
                     FROM (diets_ingredients
                       JOIN diet_participants USING (diet_id))
                    WHERE ((diet_participants.participant_id = group_meal_participants.participant_id) AND (diets_ingredients.ingredient_id = recipe_ingredients.ingredient_id)))) AS diets_match,
              ( SELECT ingredient_alternatives.alternative_id
                     FROM (ingredient_alternatives
                       CROSS JOIN LATERAL ( SELECT (EXISTS ( SELECT
                                     FROM (diets_ingredients
                                       JOIN diet_participants USING (diet_id))
                                    WHERE ((diet_participants.participant_id = group_meal_participants.participant_id) AND (diets_ingredients.ingredient_id = ingredient_alternatives.alternative_id)))) AS alternative_diets_match) alternative_table)
                    WHERE ((ingredient_alternatives.ingredient_id = recipe_ingredients.ingredient_id) AND (NOT alternative_table.alternative_diets_match))
                    ORDER BY ingredient_alternatives.priority
                   LIMIT 1) AS alternative_ingredient_id) intermediate_calculations)
       CROSS JOIN LATERAL ( SELECT ((NOT intermediate_calculations.negative_diets_match) AND ((NOT intermediate_calculations.positive_diets_exist) OR intermediate_calculations.positive_diets_exist)) AS include_ingredient_for_participant,
                  CASE intermediate_calculations.diets_match
                      WHEN true THEN intermediate_calculations.alternative_ingredient_id
                      WHEN false THEN recipe_ingredients.ingredient_id
                      ELSE NULL::bigint
                  END AS final_ingredient_id) final_calculations);
  SQL
  create_view "group_meal_participant_recipe_ingredient_calculations", sql_definition: <<-SQL
      SELECT group_meal_participant_recipe_ingredient_subst_calculations.group_id,
      group_meal_participant_recipe_ingredient_subst_calculations.meal_id,
      group_meal_participant_recipe_ingredient_subst_calculations.participant_id,
      group_meal_participant_recipe_ingredient_subst_calculations.recipe_ingredient_id,
      group_meal_participant_recipe_ingredient_subst_calculations.unit,
      hunger_calculation.hunger_quantity,
      group_meal_participant_recipe_ingredient_subst_calculations.final_ingredient_id AS ingredient_id
     FROM (((((group_meal_participant_recipe_ingredient_subst_calculations
       JOIN participants ON ((participants.id = group_meal_participant_recipe_ingredient_subst_calculations.participant_id)))
       JOIN groups ON ((groups.id = group_meal_participant_recipe_ingredient_subst_calculations.group_id)))
       JOIN ingredients ON ((ingredients.id = group_meal_participant_recipe_ingredient_subst_calculations.final_ingredient_id)))
       LEFT JOIN hunger_factors USING (age))
       CROSS JOIN LATERAL ( SELECT
                  CASE ingredients.uses_hunger_factor
                      WHEN true THEN ((group_meal_participant_recipe_ingredient_subst_calculations.normalized_quantity * COALESCE(hunger_factors.factor, (1)::numeric)) * groups.hunger_factor)
                      WHEN false THEN group_meal_participant_recipe_ingredient_subst_calculations.normalized_quantity
                      ELSE NULL::numeric
                  END AS hunger_quantity) hunger_calculation)
    WHERE group_meal_participant_recipe_ingredient_subst_calculations.include_ingredient_for_participant;
  SQL
  create_view "meal_ingredient_boxes", sql_definition: <<-SQL
      WITH meal_ingredients(meal_id, ingredient_id) AS (
           SELECT DISTINCT group_meal_participant_recipe_ingredient_calculations.meal_id,
              group_meal_participant_recipe_ingredient_calculations.ingredient_id
             FROM group_meal_participant_recipe_ingredient_calculations
          )
   SELECT meal_ingredients.meal_id,
      meal_ingredients.ingredient_id,
      ( SELECT boxes.id
             FROM boxes
            WHERE ((boxes.datetime <= meals.datetime) AND (meals.bundle OR (boxes.box_type = 1) OR ((boxes.box_type = 0) AND (ingredients.box_type <> 1)) OR ((boxes.box_type = 2) AND (ingredients.box_type = 2))))
            ORDER BY boxes.datetime DESC
           LIMIT 1) AS box_id
     FROM ((meal_ingredients
       JOIN ingredients ON ((ingredients.id = meal_ingredients.ingredient_id)))
       JOIN meals ON ((meals.id = meal_ingredients.meal_id)));
  SQL
  create_view "group_box_ingredient_units", sql_definition: <<-SQL
      WITH ingredient_sums AS (
           SELECT group_meal_participant_recipe_ingredient_calculations.group_id,
              meal_ingredient_boxes.box_id,
              group_meal_participant_recipe_ingredient_calculations.ingredient_id,
              group_meal_participant_recipe_ingredient_calculations.unit,
              sum(group_meal_participant_recipe_ingredient_calculations.hunger_quantity) AS quantity
             FROM (group_meal_participant_recipe_ingredient_calculations
               JOIN meal_ingredient_boxes USING (meal_id, ingredient_id))
            GROUP BY group_meal_participant_recipe_ingredient_calculations.group_id, meal_ingredient_boxes.box_id, group_meal_participant_recipe_ingredient_calculations.ingredient_id, group_meal_participant_recipe_ingredient_calculations.unit
          ), weighted_ingredient_sums AS (
           SELECT ingredient_sums.group_id,
              ingredient_sums.box_id,
              ingredient_sums.ingredient_id,
              packing.pack_unit,
              packing.pack_quantity
             FROM (((ingredient_sums
               LEFT JOIN ingredient_weights USING (ingredient_id, unit))
               CROSS JOIN LATERAL ( SELECT
                          CASE
                              WHEN (ingredient_weights.weight IS NOT NULL) THEN (ingredient_weights.weight * ingredient_sums.quantity)
                              WHEN ((ingredient_sums.unit)::text = 'g'::text) THEN ingredient_sums.quantity
                              ELSE NULL::numeric
                          END AS resulting_weight) weight_calculation)
               CROSS JOIN LATERAL ( SELECT COALESCE(weight_calculation.resulting_weight, ingredient_sums.quantity) AS pack_quantity,
                      ( SELECT
                                  CASE
                                      WHEN (weight_calculation.resulting_weight IS NOT NULL) THEN 'g'::character varying
                                      ELSE ingredient_sums.unit
                                  END AS unit) AS pack_unit) packing)
          ), weighted_ingredient_sums_with_extra_ingredients AS (
           SELECT weighted_ingredient_sums.group_id,
              weighted_ingredient_sums.box_id,
              weighted_ingredient_sums.ingredient_id,
              weighted_ingredient_sums.pack_unit AS unit,
              weighted_ingredient_sums.pack_quantity AS quantity
             FROM weighted_ingredient_sums
          UNION ALL
           SELECT extra_ingredients.group_id,
              extra_ingredients.box_id,
              extra_ingredients.ingredient_id,
              extra_ingredients.unit,
              extra_ingredients.quantity
             FROM extra_ingredients
          )
   SELECT weighted_ingredient_sums_with_extra_ingredients.group_id,
      weighted_ingredient_sums_with_extra_ingredients.box_id,
      weighted_ingredient_sums_with_extra_ingredients.ingredient_id,
      weighted_ingredient_sums_with_extra_ingredients.unit,
      (sum(weighted_ingredient_sums_with_extra_ingredients.quantity))::numeric(8,2) AS quantity
     FROM weighted_ingredient_sums_with_extra_ingredients
    GROUP BY weighted_ingredient_sums_with_extra_ingredients.group_id, weighted_ingredient_sums_with_extra_ingredients.box_id, weighted_ingredient_sums_with_extra_ingredients.ingredient_id, weighted_ingredient_sums_with_extra_ingredients.unit;
  SQL
  create_view "group_box_ingredient_unit_caches", materialized: true, sql_definition: <<-SQL
      SELECT group_box_ingredient_units.group_id,
      group_box_ingredient_units.box_id,
      group_box_ingredient_units.ingredient_id,
      group_box_ingredient_units.unit,
      group_box_ingredient_units.quantity
     FROM group_box_ingredient_units;
  SQL
  create_view "group_boxes", sql_definition: <<-SQL
      SELECT groups.id AS group_id,
      boxes.id AS box_id
     FROM (groups
       CROSS JOIN boxes);
  SQL
  create_view "group_meals", sql_definition: <<-SQL
      WITH group_meal_origin AS (
           SELECT DISTINCT group_meal_participations.group_id,
              group_meal_participations.meal_id,
              0 AS origin
             FROM group_meal_participations
          UNION ALL
           SELECT meal_selections.group_id,
              meal_selections.meal_id,
              1 AS origin
             FROM meal_selections
          UNION ALL
           SELECT groups.id AS group_id,
              meals.id AS meal_id,
              2 AS origin
             FROM (meals
               CROSS JOIN groups)
            WHERE (meals.optional = false)
          )
   SELECT group_meal_origin.group_id,
      group_meal_origin.meal_id,
      max(group_meal_origin.origin) AS origin
     FROM group_meal_origin
    GROUP BY group_meal_origin.group_id, group_meal_origin.meal_id;
  SQL
end
