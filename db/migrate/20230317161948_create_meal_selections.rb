class CreateMealSelections < ActiveRecord::Migration[7.0]
  def change
    create_table :meal_selections, id: false do |t|
      t.primary_keys %i[group_id meal_id]
      t.belongs_to :group, null: false, foreign_key: true
      t.belongs_to :meal, null: false, foreign_key: true

      t.timestamps
    end
  end
end
