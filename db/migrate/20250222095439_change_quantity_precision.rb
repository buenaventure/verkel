class ChangeQuantityPrecision < ActiveRecord::Migration[7.2]
  def change
    drop_view :group_box_ingredient_unit_caches, materialized: true
    drop_view :group_box_ingredient_units

    drop_view :meal_ingredient_boxes
    drop_view :group_meal_participant_recipe_ingredient_calculations
    drop_view :group_meal_participant_recipe_ingredient_subst_calculations

    change_column :article_box_order_requirements, :quantity, :decimal, precision: 10
    change_column :article_box_order_requirements, :stock, :decimal, precision: 10
    change_column :article_box_order_requirements, :ordered, :decimal, precision: 10
    change_column :articles, :quantity, :decimal, precision: 10, scale: 1
    change_column :articles, :stock, :decimal, precision: 10
    change_column :articles, :order_limit, :decimal, precision: 10
    change_column :extra_ingredients, :quantity, :decimal, precision: 9, scale: 2
    change_column :group_box_articles, :quantity, :decimal, precision: 10
    change_column :recipe_ingredients, :quantity, :decimal, precision: 9, scale: 2
    change_column :hoards, :quantity, :decimal, precision: 10
    change_column :hoards, :missing_quantity, :decimal, precision: 10
    change_column :missing_ingredients, :quantity, :decimal, precision: 10, scale: 2
    change_column :order_articles, :quantity_ordered, :decimal, precision: 10
    change_column :order_articles, :quantity_delivered, :decimal, precision: 10
    change_column :packing_lane_article_stocks, :quantity, :decimal, precision: 10
    change_column :stock_changes, :quantity, :decimal, precision: 10
    change_column :stock_changes, :result, :decimal, precision: 10

    create_view :group_meal_participant_recipe_ingredient_subst_calculations, version: 2
    create_view :group_meal_participant_recipe_ingredient_calculations
    create_view :meal_ingredient_boxes

    create_view :group_box_ingredient_units, version: 2
    create_view :group_box_ingredient_unit_caches, materialized: true

    # view group_box_ingredient_units, :quantity, precision: 10, scale: 2
  end
end
