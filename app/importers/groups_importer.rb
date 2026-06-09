class GroupsImporter
  include CSVImporter

  model Group

  column :name, as: /^name/i, required: true
  column :internal_name, as: /interner name/i
  column :packing_lane, as: /packstraße/i, to: ->(value) { PackingLane.find_or_create_by(name: value&.strip) }
  column :budget, as: /budget/i, to: ->(value) { value.presence&.tr(',', '.') }

  identifier :name
end
