class ExtraIngredientsImporter
  include CSVImporter

  model ExtraIngredient

  attr_accessor :group_id, :box_id

  column :ingredient, as: /zutat/i, required: true, to: ->(value) { Ingredient.find_by(name: value&.strip) }
  column :quantity, as: /menge/i, required: true
  column :unit, as: /einheit/i, required: true
  column :purpose, as: /verwendungszweck/i
end
