class AddExternalIdToParticipants < ActiveRecord::Migration[7.0]
  def change
    add_column :participants, :external_id, :string
    add_index :participants, :external_id, unique: true
  end
end
