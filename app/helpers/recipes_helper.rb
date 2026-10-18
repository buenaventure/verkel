module RecipesHelper
  def markdown_to_html(content)
    Kramdown::Document.new(
      content,
      Rails.application.config.kramdown_options
    ).to_html.html_safe
  end

  # Stimulus values for the ingredient autocomplete in the recipe form.
  def recipe_ingredient_autocomplete_data
    prefix = 'recipe-ingredient-autocomplete'
    {
      controller: prefix,
      "#{prefix}-units-value": (%w[g kg ml l] + Unit.order(:name).pluck(:name)).uniq.to_json,
      "#{prefix}-accepted-units-value": NormalizedQuantityUnit.accepted_units.to_json,
      "#{prefix}-ingredients-value": Ingredient.order(:name).pluck(:name).to_json,
      "#{prefix}-diets-value": Diet.order(:name).pluck(:name).to_json
    }
  end
end
