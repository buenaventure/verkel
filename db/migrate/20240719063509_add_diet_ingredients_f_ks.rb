class AddDietIngredientsFKs < ActiveRecord::Migration[7.1]
  def change
    reversible do |dir|
      dir.up do
        execute <<-SQL
          DELETE FROM positive_diet_ingredients AS p
          WHERE NOT EXISTS(
            SELECT FROM diets
            WHERE p.diet_id = diets.id)
          OR NOT EXISTS(
            SELECT FROM recipe_ingredients
            WHERE p.recipe_ingredient_id = recipe_ingredients.id);

          DELETE FROM negative_diet_ingredients AS n
          WHERE NOT EXISTS(
            SELECT FROM diets
            WHERE n.diet_id = diets.id)
          OR NOT EXISTS(
            SELECT FROM recipe_ingredients
            WHERE n.recipe_ingredient_id = recipe_ingredients.id);

          ALTER TABLE positive_diet_ingredients
            ADD CONSTRAINT positive_diet_ingredients_pkey PRIMARY KEY USING INDEX index_positive_diet_ingredients_diet_recipe_ingredient;

          ALTER TABLE negative_diet_ingredients
            ADD CONSTRAINT negative_diet_ingredients_pkey PRIMARY KEY USING INDEX index_negative_diet_ingredients_diet_recipe_ingredient;
        SQL
      end
    end

    add_foreign_key :positive_diet_ingredients, :diets
    add_foreign_key :positive_diet_ingredients, :recipe_ingredients
    add_foreign_key :negative_diet_ingredients, :diets
    add_foreign_key :negative_diet_ingredients, :recipe_ingredients
  end
end
