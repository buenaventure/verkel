class DietsIngredientsImporter
  include CSVImporter

  model Ingredient

  column :name, as: /zutat/i, required: true
  column :diet_names, as: /^(?!zutat).*/i, to: lambda { |value, ingredient, diet_column|
    if value.downcase == 'x'
      ingredient.diet_names |= [diet_column.name]
    else
      ingredient.diet_names -= [diet_column.name]
    end
  }

  identifier :name
end
