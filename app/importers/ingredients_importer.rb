class IngredientsImporter
  include CSVImporter

  model Ingredient

  column :name, as: /zutat/i, required: true
  column :commodity_group, as: /produktgruppe/i
  column :uses_hunger_factor, as: /huf/i, to: Bool
  column :box_type, as: /kistentyp/i, to: ->(value) { BOX_TYPE[value&.strip] }

  identifier :name

  BOX_TYPE = {
    'Frischekiste' => :fresh_box,
    'Grundkiste' => :base_box,
    'Standard' => :default
  }.freeze
end
