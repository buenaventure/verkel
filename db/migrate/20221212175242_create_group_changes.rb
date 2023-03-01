class CreateGroupChanges < ActiveRecord::Migration[7.0]
  def change
    enable_extension 'btree_gist'

    create_table :group_changes do |t|
      t.references :participant, null: false, foreign_key: true
      t.references :group, null: false, foreign_key: true
      t.tsrange :timeframe, null: false

      t.timestamps
    end

    reversible do |dir|
      dir.up do
        execute 'ALTER TABLE group_changes ' \
          'ADD CONSTRAINT group_changes_participant_id_timeframe_excl ' \
          'EXCLUDE USING gist (participant_id WITH =, timeframe WITH &&);'
      end
    end
  end
end
