class ArticlesImporter
  include CSVImporter

  model Article

  column :nr, required: true
  column :ingredient, as: /zutat/i, required: true, to: ->(value) { Ingredient.find_by(name: value&.strip) }
  column :supplier, as: /lieferant/i, required: true, to: ->(value) { Supplier.find_or_create_by(name: value&.strip) }
  column :quantity, as: /gebindegröße/i, required: true
  column :unit, as: /einheit/i, required: true
  column :name, as: /name/i
  column :price, as: /preis/i, to: ->(value) { value.gsub(',', '.') }
  column :priority, as: /priorität/i
  column :packing_type, as: /packart/i, required: true, to: ->(value) { PACKING_TYPE[value&.strip] }
  column :needs_cooling, as: /kühlbedarf/i, required: true, to: Bool
  column :order_limit, as: /maximale bestellmenge/i
  column :notes, as: /notiz/i

  identifier ->(article) { article.nr.present? ? :nr : [] }

  PACKING_TYPE = {
    'schütt' => :bulk,
    'stück' => :piece
  }.freeze
end
