class ParticipantsImporter
  include CSVImporter

  model Participant

  column :external_id, as: /kennung/i, required: true
  column :group, as: /kochgruppe/i, to: ->(value) { Group.find_or_create_by(name: value&.strip) }
  column :age, as: /alter/i, required: true
  column :diets, as: /ernährungsweisen/i, to: lambda { |value|
    value.split(',').map do |diet|
      Diet.find_or_create_by(name: diet)
    end
  }
  column :comment, as: /kommentar/i

  identifier ->(participant) { participant.external_id.present? ? :external_id : [] }
end
