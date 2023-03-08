class IngredientsImporter
  include CSVImporter

  model Ingredient

  column :name, as: /zutat/i, required: true
  column :commodity_group, as: /produktgruppe/i
  column :uses_hunger_factor, as: /huf/i, to: Bool
  column :box_type, as: /kistentyp/i, to: ->(value) { BOX_TYPE[value&.strip&.downcase] }

  identifier :name

  BOX_TYPE = {
    'frischekiste' => :fresh_box,
    'grundkiste' => :base_box,
    'standard' => :default
  }.freeze
end
