class ExtraIngredientsImporter
  include CSVImporter

  model ExtraIngredient

  column :ingredient, as: /zutat/i, required: true, to: ->(value) { Ingredient.find_by(name: value&.strip) }
  column :quantity, as: /menge/i, required: true
  column :unit, as: /einheit/i, required: true
  column :purpose, as: /verwendungszweck/i
end
